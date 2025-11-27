package main

import (
	"bufio"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
)

// Convert Go coverage profile (cover.out) to LCOV format
// Go coverage format: name.go:line.column,line.column numStmt count
// LCOV format: SF:file, DA:line,count, LF:total, LH:hit, end_of_record

func main() {
	if len(os.Args) != 3 {
		fmt.Fprintf(os.Stderr, "Usage: %s <cover.out> <output.lcov>\n", os.Args[0])
		os.Exit(1)
	}

	inputFile := os.Args[1]
	outputFile := os.Args[2]

	file, err := os.Open(inputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening input file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Map of filename -> line -> count
	coverage := make(map[string]map[int]int)

	scanner := bufio.NewScanner(file)
	lineNum := 0
	for scanner.Scan() {
		lineNum++
		line := scanner.Text()

		// Skip the mode line (first line)
		if strings.HasPrefix(line, "mode:") {
			continue
		}

		// Parse: filepath:startLine.startCol,endLine.endCol numStmt count
		// Example: gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/helpers.go:15.34,17.2 1 5
		colonIdx := strings.LastIndex(line, ":")
		if colonIdx == -1 {
			continue
		}

		filepath := line[:colonIdx]
		rest := line[colonIdx+1:]

		// Parse the position and counts
		parts := strings.Fields(rest)
		if len(parts) != 2 {
			continue
		}

		positions := parts[0]
		countStr := parts[1]

		count, err := strconv.Atoi(countStr)
		if err != nil {
			continue
		}

		// Parse start and end positions: startLine.startCol,endLine.endCol
		posParts := strings.Split(positions, ",")
		if len(posParts) != 2 {
			continue
		}

		startParts := strings.Split(posParts[0], ".")
		endParts := strings.Split(posParts[1], ".")
		if len(startParts) != 2 || len(endParts) != 2 {
			continue
		}

		startLine, err := strconv.Atoi(startParts[0])
		if err != nil {
			continue
		}
		endLine, err := strconv.Atoi(endParts[0])
		if err != nil {
			continue
		}

		// Strip the module prefix to get relative path
		// gitlab.com/gitlab-org/gitlab/workhorse/... -> workhorse/...
		relPath := filepath
		if idx := strings.Index(filepath, "workhorse/"); idx != -1 {
			relPath = filepath[idx:]
		}

		// Initialize map for this file if needed
		if coverage[relPath] == nil {
			coverage[relPath] = make(map[int]int)
		}

		// Add coverage for each line in the block
		for l := startLine; l <= endLine; l++ {
			coverage[relPath][l] += count
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Write LCOV output
	out, err := os.Create(outputFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating output file: %v\n", err)
		os.Exit(1)
	}
	defer out.Close()

	// Sort filenames for consistent output
	filenames := make([]string, 0, len(coverage))
	for filename := range coverage {
		filenames = append(filenames, filename)
	}
	sort.Strings(filenames)

	for _, filename := range filenames {
		lines := coverage[filename]

		fmt.Fprintf(out, "TN:\n")
		fmt.Fprintf(out, "SF:%s\n", filename)

		// Sort line numbers
		lineNums := make([]int, 0, len(lines))
		for line := range lines {
			lineNums = append(lineNums, line)
		}
		sort.Ints(lineNums)

		linesFound := 0
		linesHit := 0
		for _, line := range lineNums {
			count := lines[line]
			fmt.Fprintf(out, "DA:%d,%d\n", line, count)
			linesFound++
			if count > 0 {
				linesHit++
			}
		}

		fmt.Fprintf(out, "LF:%d\n", linesFound)
		fmt.Fprintf(out, "LH:%d\n", linesHit)
		fmt.Fprintf(out, "end_of_record\n")
	}

	fmt.Printf("Converted %d files to LCOV format: %s\n", len(filenames), outputFile)
}
