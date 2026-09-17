# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::RegoPackage do
  describe ".declared_in" do
    it "reads a bare declaration" do
      expect(described_class.declared_in("package governance\n\nallow := true\n")).to eq("governance")
    end

    it "reads past leading comments and blank lines" do
      commented = "# authored by hand\n\npackage governance\n\nallow := true\n"

      expect(described_class.declared_in(commented)).to eq("governance")
    end

    it "reads past a trailing comment with a preceding space" do
      annotated = "package governance # deployment freeze\n\nallow := true\n"

      expect(described_class.declared_in(annotated)).to eq("governance")
    end

    it "reads past a trailing comment with no preceding space" do
      annotated = "package governance#freeze\n\nallow := true\n"

      expect(described_class.declared_in(annotated)).to eq("governance")
    end

    it "reads a subpackage rather than truncating it at the dot" do
      expect(described_class.declared_in("package governance.deploy\n\nallow := true\n")).to eq("governance.deploy")
    end

    it "returns nil when the source declares no package" do
      expect(described_class.declared_in("allow := true\n")).to be_nil
    end
  end

  describe ".split_header" do
    it "removes a bare declaration line, leaving the rest untouched" do
      source = "package governance\n\nallow := true\n"

      expect(described_class.split_header(source)).to eq(["\nallow := true\n", []])
    end

    it "removes only the declaration line, keeping a leading comment" do
      source = "# authored by hand\npackage governance\n\nallow := true\n"

      expect(described_class.split_header(source)).to eq(["# authored by hand\n\nallow := true\n", []])
    end

    it "removes a declaration carrying a trailing comment" do
      source = "package governance # deployment freeze\n\nallow := true\n"

      expect(described_class.split_header(source)).to eq(["\nallow := true\n", []])
    end

    it "lifts the imports between the declaration and the first rule, without their comments" do
      source = "package governance\n\nimport rego.v1\nimport data.approvals as a # runbook\n\nallow if true\n"

      expect(described_class.split_header(source))
        .to eq(["\n\nallow if true\n", ["import rego.v1", "import data.approvals as a"]])
    end

    it "stops at the first rule, leaving a later import in the body" do
      source = "package governance\n\nallow := true\n\nimport rego.v1\n"

      expect(described_class.split_header(source)).to eq(["\nallow := true\n\nimport rego.v1\n", []])
    end

    it "returns the source unchanged when it declares no package" do
      source = "allow := true\n"

      expect(described_class.split_header(source)).to eq([source, []])
    end

    it "does not strip a later line that merely reads like a declaration, agreeing with .declared_in",
      :aggregate_failures do
      source = "allow := true\n# a note that happens to read like\npackage decoy\n\nmore := 1\n"

      expect(described_class.declared_in(source)).to be_nil
      expect(described_class.split_header(source)).to eq([source, []])
    end
  end

  describe ".header" do
    it "renders only the package line when there are no imports" do
      expect(described_class.header([])).to eq("package governance\n")
    end

    it "renders the imports under the package line, separated from it by a blank line" do
      expect(described_class.header(["import rego.v1", "import data.approvals as a"]))
        .to eq("package governance\n\nimport rego.v1\nimport data.approvals as a\n")
    end

    it "keeps one copy of an import several rules share" do
      imports = ["import rego.v1", "import data.approvals as a", "import rego.v1"]

      expect(described_class.header(imports))
        .to eq("package governance\n\nimport rego.v1\nimport data.approvals as a\n")
    end
  end
end
