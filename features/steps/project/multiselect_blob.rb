class ProjectMultiselectBlob < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  class << self
    def click_line_steps(*line_numbers)
      line_numbers.each do |line_number|
        step "I click line #{line_number} in file" do
          find("#L#{line_number}").click
        end

        step "I shift-click line #{line_number} in file" do
          script = "$('#L#{line_number}').trigger($.Event('click', { shiftKey: true }));"
          page.evaluate_script(script)
        end
      end
    end

    def check_state_steps(*ranges)
      ranges.each do |range|
        fragment = range.kind_of?(Array) ? "L#{range.first}-#{range.last}" : "L#{range}"
        pluralization = range.kind_of?(Array) ? "s" : ""

        step "I should see \"#{fragment}\" as URI fragment" do
          URI.parse(current_url).fragment.should == fragment
        end

        step "I should see line#{pluralization} #{fragment[1..-1]} highlighted" do
          ids = Array(range).map { |n| "LC#{n}" }
          extra = false

          highlighted = all("#tree-content-holder .highlight .line.hll")
          highlighted.each do |element|
            extra ||= ids.delete(element[:id]).nil?
          end

          extra.should be_false and ids.should be_empty
        end
      end
    end
  end

  click_line_steps *Array(1..5)
  check_state_steps *Array(1..5), Array(1..2), Array(1..3), Array(1..4), Array(1..5), Array(3..5)

  step 'I go back in history' do
    page.evaluate_script("window.history.back()")
  end

  step 'I go forward in history' do
    page.evaluate_script("window.history.forward()")
  end

  step 'I click on "Gemfile.lock" file in repo' do
    click_link "Gemfile.lock"
  end
end
