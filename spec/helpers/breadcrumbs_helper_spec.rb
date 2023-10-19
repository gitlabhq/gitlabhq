# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BreadcrumbsHelper do
  describe '#push_to_schema_breadcrumb' do
    let(:element_name) { 'BreadCrumbElement' }
    let(:link) { 'http://test.host/foo' }
    let(:breadcrumb_list) { helper.instance_variable_get(:@schema_breadcrumb_list) }

    subject { helper.push_to_schema_breadcrumb(element_name, link) }

    it 'enqueue element name, link and position' do
      subject

      aggregate_failures do
        expect(breadcrumb_list[0]['name']).to eq element_name
        expect(breadcrumb_list[0]['item']).to eq link
        expect(breadcrumb_list[0]['position']).to eq(1)
      end
    end

    context 'when link is relative' do
      let(:link) { '/foo' }

      it 'converts the url into absolute' do
        subject

        expect(breadcrumb_list[0]['item']).to eq "http://test.host#{link}"
      end
    end

    describe 'when link is invalid' do
      let(:link) { 'invalid://foo[]' }

      it 'returns the current url' do
        subject

        expect(breadcrumb_list[0]['item']).to eq 'http://test.host'
      end
    end

    describe 'when link is nil' do
      let(:link) { nil }

      it 'returns the current url' do
        subject

        expect(breadcrumb_list[0]['item']).to eq 'http://test.host'
      end
    end
  end

  describe '#schema_breadcrumb_json' do
    let(:elements) do
      [
        %w[element1 http://test.host/link1],
        %w[element2 http://test.host/link2]
      ]
    end

    subject { helper.schema_breadcrumb_json }

    it 'returns the breadcrumb schema in json format' do
      enqueue_breadcrumb_elements

      expected_result = {
        '@context' => 'https://schema.org',
        '@type' => 'BreadcrumbList',
        'itemListElement' => [
          {
            '@type' => 'ListItem',
            'position' => 1,
            'name' => elements[0][0],
            'item' => elements[0][1]
          },
          {
            '@type' => 'ListItem',
            'position' => 2,
            'name' => elements[1][0],
            'item' => elements[1][1]
          }
        ]
      }.to_json

      expect(subject).to eq expected_result
    end

    context 'when extra breadcrumb element is added' do
      let(:extra_elements) do
        [
          %w[extra_element1 http://test.host/extra_link1],
          %w[extra_element2 http://test.host/extra_link2]
        ]
      end

      it 'include the extra elements before the last element' do
        enqueue_breadcrumb_elements

        extra_elements.each do |el|
          add_to_breadcrumbs(el[0], el[1])
        end

        expected_result = {
          '@context' => 'https://schema.org',
          '@type' => 'BreadcrumbList',
          'itemListElement' => [
            {
              '@type' => 'ListItem',
              'position' => 1,
              'name' => elements[0][0],
              'item' => elements[0][1]
            },
            {
              '@type' => 'ListItem',
              'position' => 2,
              'name' => extra_elements[0][0],
              'item' => extra_elements[0][1]
            },
            {
              '@type' => 'ListItem',
              'position' => 3,
              'name' => extra_elements[1][0],
              'item' => extra_elements[1][1]
            },
            {
              '@type' => 'ListItem',
              'position' => 4,
              'name' => elements[1][0],
              'item' => elements[1][1]
            }
          ]
        }.to_json

        expect(subject).to eq expected_result
      end
    end

    def enqueue_breadcrumb_elements
      elements.each do |el|
        helper.push_to_schema_breadcrumb(el[0], el[1])
      end
    end
  end
end
