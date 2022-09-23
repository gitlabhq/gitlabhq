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
      expect(page).to have_css ".progress-bar[style='width: #{value}%;']"
    end
  end

  describe "variant" do
    where(:variant) { [:primary, :success] }

    with_them do
      it "adds variant class" do
        expect(page).to have_css ".progress-bar.bg-#{variant}"
      end
    end

    context "with unknown variant" do
      let(:variant) { :nope }

      it "adds the default variant class" do
        expect(page).to have_css ".progress-bar.bg-primary"
      end
    end
  end
end
