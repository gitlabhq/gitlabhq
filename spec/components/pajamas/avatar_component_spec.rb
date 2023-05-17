# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::AvatarComponent, type: :component do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  let(:options) { {} }

  before do
    render_inline(described_class.new(record, **options))
  end

  describe "avatar shape" do
    context "for a User" do
      let(:record) { user }

      it "has a circle shape" do
        expect(page).to have_css ".gl-avatar.gl-avatar-circle"
      end
    end

    context "for a Project" do
      let(:record) { project }

      it "has default shape (rect)" do
        expect(page).to have_css ".gl-avatar"
        expect(page).not_to have_css ".gl-avatar-circle"
      end
    end

    context "for a Group" do
      let(:record) { group }

      it "has default shape (rect)" do
        expect(page).to have_css ".gl-avatar"
        expect(page).not_to have_css ".gl-avatar-circle"
      end
    end
  end

  describe "avatar image" do
    context "when it has an uploaded image" do
      let(:record) { project }

      before do
        allow(record).to receive(:avatar_url).and_return "/example.png"
        render_inline(described_class.new(record, **options))
      end

      it "uses the avatar_url as image src" do
        expect(page).to have_css "img.gl-avatar[src='/example.png?width=64']"
      end

      it "uses a srcset for higher resolution on retina displays" do
        expect(page).to have_css "img.gl-avatar[srcset='/example.png?width=64 1x, /example.png?width=128 2x']"
      end

      it "uses lazy loading" do
        expect(page).to have_css "img.gl-avatar[loading='lazy']"
      end

      context "with size option" do
        let(:options) { { size: 16 } }

        it "uses that size as param for image src and srcset" do
          expect(page).to have_css(
            "img.gl-avatar[src='/example.png?width=16'][srcset='/example.png?width=16 1x, /example.png?width=32 2x']"
          )
        end
      end
    end

    context "when a project or group has no uploaded image" do
      let(:record) { project }

      it "uses an identicon with the record's initial" do
        expect(page).to have_css "div.gl-avatar.gl-avatar-identicon", text: record.name[0].upcase
      end

      context "when the record has no id" do
        let(:record) { build :group }

        it "uses an identicon with default background color" do
          expect(page).to have_css "div.gl-avatar.gl-avatar-identicon-bg1"
        end
      end
    end

    context "when a user has no uploaded image" do
      let(:record) { user }

      it "uses a gravatar" do
        expect(rendered_content).to match /gravatar\.com/
      end
    end
  end

  describe "options" do
    let(:record) { user }

    describe "alt" do
      context "with a value" do
        let(:options) { { alt: "Profile picture" } }

        it "uses given value as alt text" do
          expect(page).to have_css ".gl-avatar[alt='Profile picture']"
        end
      end

      context "without a value" do
        it "uses the record's name as alt text" do
          expect(page).to have_css ".gl-avatar[alt='#{record.name}']"
        end
      end
    end

    describe "class" do
      let(:options) { { class: 'gl-m-4' } }

      it 'has the correct custom class' do
        expect(page).to have_css '.gl-avatar.gl-m-4'
      end
    end

    describe "size" do
      let(:options) { { size: 96 } }

      it 'has the correct size class' do
        expect(page).to have_css '.gl-avatar.gl-avatar-s96'
      end
    end
  end
end
