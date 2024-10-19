# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::ProgressComponent, type: :component do
  before do
    render_inline(described_class.new(value: value, variant: variant))
  end

  let(:value) { 33 }
  let(:variant) { nil }

  describe "value" do
    it "sets the width of the progressbar" do
      expect(page).to have_css ".gl-progress[style='width: #{value}%;']"
    end
  end

  describe "variant" do
    where(:variant) { [:primary, :success] }

    with_them do
      it "adds variant class" do
        expect(page).to have_css ".gl-progress.gl-progress-bar-#{variant}"
      end
    end

    context "with unknown variant" do
      let(:variant) { :nope }

      it "adds the default variant class" do
        expect(page).to have_css ".gl-progress.gl-progress-bar-primary"
      end
    end
  end
end
