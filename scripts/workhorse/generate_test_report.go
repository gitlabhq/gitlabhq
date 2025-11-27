package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// GoTestEvent represents a single event from go test -json output
type GoTestEvent struct {
	Time    time.Time
	Action  string
	Package string
	Test    string
	Output  string
	Elapsed float64
}

// RSpecExample represents a test example in RSpec report format
type RSpecExample struct {
	ID              string      `json:"id"`
	Description     string      `json:"description"`
	FullDescription string      `json:"full_description"`
	Status          string      `json:"status"`
	FilePath        string      `json:"file_path"`
	LineNumber      int         `json:"line_number"`
	RunTime         float64     `json:"run_time"`
	FeatureCategory interface{} `json:"feature_category"`
}

// RSpecReport represents the complete RSpec-compatible test report
type RSpecReport struct {
	Version  string         `json:"version"`
	Examples []RSpecExample `json:"examples"`
}

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <go-test-json-file> <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := os.Args[2]

	// Read and parse go test JSON events
	file, err := os.Open(inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening input file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	examples := []RSpecExample{}
	testResults := make(map[string]*GoTestEvent)
	testPackages := make(map[string]string)

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		var event GoTestEvent
		if err := json.Unmarshal(scanner.Bytes(), &event); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: Failed to parse test event: %v\n", err)
			continue
		}

		if event.Test == "" {
			continue
		}

		testKey := event.Package + "::" + event.Test

		switch event.Action {
		case "run":
			testPackages[testKey] = event.Package
		case "pass", "fail", "skip":
			testResults[testKey] = &event
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Convert test results to RSpec format
	for testKey, event := range testResults {
		pkg := testPackages[testKey]
		if pkg == "" {
			continue
		}

		// Convert package path to file path
		// e.g., "gitlab.com/gitlab-org/gitlab/workhorse/internal/helper" -> "workhorse/internal/helper"
		relPkg := strings.TrimPrefix(pkg, "gitlab.com/gitlab-org/gitlab/")

		// Find the test file (assume it's in the package directory)
		testFile := findTestFile(relPkg, event.Test)

		status := "passed"
		if event.Action == "fail" {
			status = "failed"
		} else if event.Action == "skip" {
			status = "pending"
		}

		example := RSpecExample{
			ID:              fmt.Sprintf("%s[%s]", testFile, event.Test),
			Description:     event.Test,
			FullDescription: fmt.Sprintf("%s %s", pkg, event.Test),
			Status:          status,
			FilePath:        testFile,
			LineNumber:      1,
			RunTime:         event.Elapsed,
			FeatureCategory: nil,
		}

		examples = append(examples, example)
	}

	// Generate RSpec report
	report := RSpecReport{
		Version:  "1.0.0",
		Examples: examples,
	}

	// Write output
	output, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating JSON: %v\n", err)
		os.Exit(1)
	}

	if err := os.WriteFile(outputFile, output, 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing output file: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("✓ Generated test report: %s\n", outputFile)
	fmt.Printf("  Total tests: %d\n", len(examples))
}

// findTestFile attempts to find the test file for a given test name in a package
func findTestFile(pkgPath, testName string) string {
	// Try to find matching test file
	pattern := filepath.Join(pkgPath, "*_test.go")
	matches, err := filepath.Glob(pattern)

	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Failed to find test files in %s: %v\n", pkgPath, err)
		return filepath.Join(pkgPath, "test.go")
	}

	if len(matches) == 0 {
		fmt.Fprintf(os.Stderr, "Warning: No test files found in %s\n", pkgPath)
		return filepath.Join(pkgPath, "test.go")
	}

	// Return the first matching test file
	// In practice, we'd need more sophisticated logic to match test names to files
	return matches[0]
}
