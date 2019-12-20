# frozen_string_literal: true

FactoryBot.define do
  factory :error_tracking_error_event, class: Gitlab::ErrorTracking::ErrorEvent do
    issue_id { 'id' }
    date_received { Time.now.iso8601 }
    stack_trace_entries do
      [
        {
          'function' => 'puts',
          'lineNo' => 14,
          'filename' => 'hello_world.rb',
          'context' => [
            [10, "# Ruby example\n"],
            [11, "class HelloWorld\n"],
            [12, "  def self.message\n"],
            [13, "    @name = 'World'\n"],
            [14, "    puts \"Hello \#{@name}\"\n"],
            [15, "  end\n"],
            [16, "end\n"]
          ]
        },
        {
          'function' => 'print',
          'lineNo' => 6,
          'filename' => 'HelloWorld.swift',
          'context' => [
            [1, "// Swift example\n"],
            [2, "struct HelloWorld {\n"],
            [3, "    let name = \"World\"\n"],
            [4, "\n"],
            [5, "    static func message() {\n"],
            [6, "        print(\"Hello, \\(self.name)\")\n"],
            [7, "    }\n"],
            [8, "}\n"]
          ]
        },
        {
          'filename' => 'blank.txt'
        }
      ]
    end

    skip_create
  end
end
