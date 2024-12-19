# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::NoPreviewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:web_component) { page.find('diff-file') }

  shared_examples 'file mode changed' do
    before do
      allow(diff_file).to receive_messages(mode_changed?: true, a_mode: 100500, b_mode: 100755)
    end

    it 'shows changed file message' do
      render_component
      expect(page).to have_text("File mode changed from #{diff_file.a_mode} to #{diff_file.b_mode}.")
    end
  end

  describe 'change type' do
    context 'with a changed file' do
      before do
        allow(diff_file).to receive(:content_changed?).and_return(true)
      end

      it 'shows changed file message' do
        render_component
        expect(page).to have_text('File changed.')
      end

      include_examples 'file mode changed'
    end

    context 'with a moved file' do
      before do
        allow(diff_file).to receive_messages(content_changed?: false, renamed_file?: true)
      end

      it 'shows moved file message' do
        render_component
        expect(page).to have_text('File moved.')
      end

      include_examples 'file mode changed'

      context 'with a changed file' do
        before do
          allow(diff_file).to receive(:content_changed?).and_return(true)
        end

        it 'shows changed file message' do
          render_component
          expect(page).to have_text("File changed and moved.")
        end
      end
    end

    context 'with a new file' do
      before do
        allow(diff_file).to receive(:new_file?).and_return(true)
      end

      it 'shows added file message' do
        render_component
        expect(page).to have_text('File added.')
      end
    end

    context 'with a deleted file' do
      before do
        allow(diff_file).to receive(:deleted_file?).and_return(true)
      end

      it 'shows deleted file message' do
        render_component
        expect(page).to have_text('File deleted.')
      end
    end

    include_examples 'file mode changed'
  end

  describe 'no preview reason' do
    context 'when file is too large' do
      before do
        allow(diff_file).to receive(:too_large?).and_return(true)
      end

      it 'shows limit message' do
        render_component
        expect(page).to have_text("File size exceeds preview limit.")
      end
    end

    context 'when diff is too large' do
      before do
        allow(diff_file).to receive(:collapsed?).and_return(true)
      end

      it 'shows limit message' do
        render_component
        expect(page).to have_text("Preview size limit exceeded, changes collapsed.")
      end
    end

    context 'with a non-diffable file' do
      before do
        allow(diff_file).to receive(:diffable?).and_return(false)
      end

      it 'shows suppressed message' do
        render_component
        message = "Preview suppressed by a .gitattributes entry or the file's encoding is unsupported."
        expect(page).to have_text(message)
      end
    end

    context 'with a new file' do
      before do
        allow(diff_file).to receive(:new_file?).and_return(true)
      end

      it 'shows no preview message' do
        render_component
        expect(page).to have_text("No diff preview for this file type.")
      end
    end

    context 'with a changed file' do
      before do
        allow(diff_file).to receive(:content_changed?).and_return(true)
      end

      it 'shows no preview message' do
        render_component
        expect(page).to have_text("No diff preview for this file type.")
      end
    end
  end

  describe 'actions' do
    shared_examples 'view file' do
      it 'shows view file link' do
        render_component
        expect(page).to have_link("View file")
      end
    end

    context 'when file is previewable' do
      before do
        allow(diff_file).to receive(:diffable_text?).and_return(true)
      end

      it 'shows no preview message' do
        render_component
        expect(page).to have_button("Show file contents")
      end

      context 'when diff is too large' do
        before do
          allow(diff_file).to receive(:collapsed?).and_return(true)
        end

        it 'shows no preview message' do
          render_component
          expect(page).to have_button("Show changes")
        end
      end
    end

    context 'when file is not previewable' do
      before do
        allow(diff_file).to receive(:diffable_text?).and_return(false)
      end

      context 'with a deleted file' do
        before do
          allow(diff_file).to receive_messages(content_changed?: false, deleted_file?: true)
        end

        include_examples 'view file'
      end

      context 'with a changed file' do
        before do
          allow(diff_file).to receive(:content_changed?).and_return(true)
        end

        it 'shows no preview message' do
          render_component
          expect(page).to have_link("View original file")
          expect(page).to have_link("View changed file")
        end
      end

      context 'with an unchanged file' do
        before do
          allow(diff_file).to receive(:content_changed?).and_return(false)
        end

        context 'with a new file' do
          before do
            allow(diff_file).to receive(:new_file?).and_return(true)
          end

          include_examples 'view file'
        end

        context 'with a renamed file' do
          before do
            allow(diff_file).to receive(:renamed_file?).and_return(true)
          end

          include_examples 'view file'
        end

        context 'with a changed file mode' do
          before do
            allow(diff_file).to receive(:mode_changed?).and_return(true)
          end

          include_examples 'view file'
        end
      end
    end
  end

  def render_component(**args)
    render_inline(described_class.new(diff_file: diff_file, **args))
  end
end
