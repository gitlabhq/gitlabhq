require 'spec_helper'

describe SnippetsHelper do
  include IconsHelper

  describe '#reliable_snippet_path' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full path' do
          snippet = create(:personal_snippet, :public)

          expect(reliable_snippet_path(snippet)).to eq('/snippets/1')
        end
      end

      context 'secret' do
        it 'gives a full path, including secret word' do
          snippet = create(:personal_snippet, :secret)

          expect(reliable_snippet_path(snippet)).to match(%r{/snippets/2\?secret=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full path' do
        snippet = create(:project_snippet, :public)

        expect(reliable_snippet_path(snippet)).to eq('/namespace1/project1/snippets/3')
      end
    end
  end

  describe '#reliable_snippet_url' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full url' do
          snippet = create(:personal_snippet, :public)

          expect(reliable_snippet_url(snippet)).to eq('http://test.host/snippets/1')
        end
      end

      context 'secret' do
        it 'gives a full url, including secret word' do
          snippet = create(:personal_snippet, :secret)

          expect(reliable_snippet_url(snippet)).to match(%r{http://test.host/snippets/2\?secret=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full url' do
        snippet = create(:project_snippet, :public)

        expect(reliable_snippet_url(snippet)).to eq('http://test.host/namespace1/project1/snippets/3')
      end
    end
  end

  describe '#shareable_snippets_link' do
    context 'personal snippets' do
      context 'public' do
        it 'gives a full link' do
          snippet = create(:personal_snippet, :public)

          expect(reliable_snippet_url(snippet)).to eq('/snippets/1')
        end
      end

      context 'secret' do
        it 'gives a full link, including secret word' do
          snippet = create(:personal_snippet, :secret)

          expect(reliable_snippet_url(snippet)).to eq(%r{/snippets/2\?secret=\w+})
        end
      end
    end

    context 'project snippets' do
      it 'gives a full link' do
        snippet = create(:project_snippet, :public)

        expect(reliable_snippet_url(snippet)).to eq('/namespace1/project1/snippets/3')
      end
    end
  end

  describe '#embedded_snippet_raw_button' do
    it 'gives view raw button of embedded snippets for project snippets' do
      @snippet = create(:project_snippet, :public)

      expect(embedded_snippet_raw_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{raw_project_snippet_url(@snippet.project, @snippet)}\">#{external_snippet_icon('doc_code')}</a>")
    end

    it 'gives view raw button of embedded snippets for personal snippets' do
      @snippet = create(:personal_snippet, :public)

      expect(embedded_snippet_raw_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{raw_snippet_url(@snippet)}\">#{external_snippet_icon('doc_code')}</a>")
    end
  end

  describe '#embedded_snippet_download_button' do
    it 'gives download button of embedded snippets for project snippets' do
      @snippet = create(:project_snippet, :public)

      expect(embedded_snippet_download_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{raw_project_snippet_url(@snippet.project, @snippet, inline: false)}\">#{external_snippet_icon('download')}</a>")
    end

    it 'gives download button of embedded snippets for personal snippets' do
      @snippet = create(:personal_snippet, :public)

      expect(embedded_snippet_download_button.to_s).to eq("<a class=\"btn\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{raw_snippet_url(@snippet, inline: false)}\">#{external_snippet_icon('download')}</a>")
    end
  end
end
