require 'spec_helper'

describe SnippetsHelper do
  include IconsHelper

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
