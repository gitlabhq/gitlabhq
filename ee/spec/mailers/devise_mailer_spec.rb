require 'spec_helper'
require 'email_spec'

describe DeviseMailer do
  describe "#confirmation_instructions" do
    let(:unsaved_user) { create(:user, name: 'Jane Doe', email: 'jdoe@example.com') }
    let(:custom_text) { 'this is some additional custom text' }

    subject { described_class.confirmation_instructions(unsaved_user, 'faketoken', {}) }

    before do
      stub_licensed_features(email_additional_text: true)
      stub_ee_application_setting(email_additional_text: custom_text)
    end

    it "includes the additonal custom text" do
      expect(subject).to have_text custom_text
    end
  end
end
