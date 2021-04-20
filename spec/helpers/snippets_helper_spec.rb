# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SnippetsHelper do
  include Gitlab::Routing
  include IconsHelper

  let_it_be(:public_personal_snippet) { create(:personal_snippet, :public, :repository) }
  let_it_be(:public_project_snippet) { create(:project_snippet, :public, :repository) }

  describe '#embedded_raw_snippet_button' do
    let(:blob) { snippet.blobs.first }
    let(:ref) { blob.repository.root_ref }

    subject { embedded_raw_snippet_button(snippet, blob) }

    context 'for Personal Snippets' do
      let(:snippet) { public_personal_snippet }

      it 'returns view raw button of embedded snippets' do
        expect(subject).to eq(download_link("http://test.host/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"))
      end
    end

    context 'for Project Snippets' do
      let(:snippet) { public_project_snippet }

      it 'returns view raw button of embedded snippets' do
        expect(subject).to eq(download_link("http://test.host/#{snippet.project.path_with_namespace}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"))
      end
    end

    def download_link(url)
      "<a class=\"gl-button btn btn-default\" target=\"_blank\" rel=\"noopener noreferrer\" title=\"Open raw\" href=\"#{url}\">#{external_snippet_icon('doc-code')}</a>"
    end
  end

  describe '#embedded_snippet_download_button' do
    let(:blob) { snippet.blobs.first }
    let(:ref) { blob.repository.root_ref }

    subject { embedded_snippet_download_button(snippet, blob) }

    context 'for Personal Snippets' do
      let(:snippet) { public_personal_snippet }

      it 'returns download button of embedded snippets' do
        expect(subject).to eq(download_link("http://test.host/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"))
      end
    end

    context 'for Project Snippets' do
      let(:snippet) { public_project_snippet }

      it 'returns download button of embedded snippets' do
        expect(subject).to eq(download_link("http://test.host/#{snippet.project.path_with_namespace}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"))
      end
    end

    def download_link(url)
      "<a class=\"gl-button btn btn-default\" target=\"_blank\" title=\"Download\" rel=\"noopener noreferrer\" href=\"#{url}?inline=false\">#{external_snippet_icon('download')}</a>"
    end
  end

  describe '#snippet_badge' do
    let(:snippet) { build(:personal_snippet, visibility) }

    subject { snippet_badge(snippet) }

    context 'when snippet is private' do
      let(:visibility) { :private }

      it 'returns the snippet badge' do
        expect(subject).to eq "<span class=\"badge badge-gray\">#{sprite_icon('lock', size: 14, css_class: 'gl-vertical-align-middle')} private</span>"
      end
    end

    context 'when snippet is public' do
      let(:visibility) { :public }

      it 'does not return anything' do
        expect(subject).to be_nil
      end
    end

    context 'when snippet is internal' do
      let(:visibility) { :internal }

      it 'does not return anything' do
        expect(subject).to be_nil
      end
    end
  end
end
