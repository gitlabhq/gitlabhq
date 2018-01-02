require 'spec_helper'

describe Banzai::Filter::EpicReferenceFilter do
  include FilterSpecHelper

  let(:urls) { Gitlab::Routing.url_helpers }

  let(:group) { create(:group) }
  let(:another_group) { create(:group) }
  let(:epic) { create(:epic, group: group) }
  let(:full_ref_text) { "Check #{epic.group.full_path}&#{epic.iid}" }

  def doc(reference = nil)
    reference ||= "Check &#{epic.iid}"
    context = { project: nil, group: group }

    reference_filter(reference, context)
  end

  context 'internal reference' do
    let(:reference) { "&#{epic.iid}" }

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href')).to eq(urls.group_epic_url(group, epic))
    end

    it 'links with adjacent text' do
      expect(doc.text).to eq("Check #{reference}")
    end

    it 'includes a title attribute' do
      expect(doc.css('a').first.attr('title')).to eq(epic.title)
    end

    it 'escapes the title attribute' do
      epic.update_attribute(:title, %{"></a>whatever<a title="})

      expect(doc.text).to eq("Check #{reference}")
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end

    it 'includes a data-group attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-group')
      expect(link.attr('data-group')).to eq(group.id.to_s)
    end

    it 'includes a data-epic attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-epic')
      expect(link.attr('data-epic')).to eq(epic.id.to_s)
    end

    it 'includes a data-original attribute' do
      link = doc.css('a').first

      expect(link).to have_attribute('data-original')
      expect(link.attr('data-original')).to eq(reference)
    end

    it 'ignores invalid epic IDs' do
      text = "Check &9999"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'does not process links containing epic numbers followed by text' do
      href = "#{reference}st"
      link = doc("<a href='#{href}'></a>").css('a').first.attr('href')

      expect(link).to eq(href)
    end
  end

  context 'internal escaped reference' do
    let(:reference) { "&amp;#{epic.iid}" }

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href')).to eq(urls.group_epic_url(group, epic))
    end

    it 'includes a title attribute' do
      expect(doc.css('a').first.attr('title')).to eq(epic.title)
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end

    it 'ignores invalid epic IDs' do
      text = "Check &amp;9999"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end
  end

  context 'cross-reference' do
    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'escaped cross-reference' do
    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &amp;#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'subgroup cross-reference' do
    before do
      subgroup = create(:group, parent: another_group)
      epic.update_attribute(:group_id, subgroup.id)
    end

    it 'ignores a shorthand reference from another group' do
      text = "Check &#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'ignores reference with incomplete group path' do
      text = "Check @#{epic.group.path}&#{epic.iid}"

      expect(doc(text).to_s).to eq(ERB::Util.html_escape_once(text))
    end

    it 'links to a valid reference for full reference' do
      expect(doc(full_ref_text).css('a').first.attr('href')).to eq(urls.group_epic_url(epic.group, epic))
    end

    it 'link has valid text' do
      expect(doc(full_ref_text).css('a').first.text).to eq("#{epic.group.full_path}&#{epic.iid}")
    end

    it 'includes default classes' do
      expect(doc(full_ref_text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'url reference' do
    let(:link) { urls.group_epic_url(epic.group, epic) }
    let(:text) { "Check #{link}" }

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq(epic.to_reference(group))
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'full cross-refererence in a link href' do
    let(:link) { "#{another_group.path}&#{epic.iid}" }
    let(:text) do
      ref = %{<a href="#{link}">Reference</a>}
      "Check #{ref}"
    end

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference for link href' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq('Reference')
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end

  context 'url in a link href' do
    let(:link) { urls.group_epic_url(epic.group, epic) }
    let(:text) do
      ref = %{<a href="#{link}">Reference</a>}
      "Check #{ref}"
    end

    before do
      epic.update_attribute(:group_id, another_group.id)
    end

    it 'links to a valid reference for link href' do
      expect(doc(text).css('a').first.attr('href')).to eq(urls.group_epic_url(another_group, epic))
    end

    it 'link has valid text' do
      expect(doc(text).css('a').first.text).to eq('Reference')
    end

    it 'includes default classes' do
      expect(doc(text).css('a').first.attr('class')).to eq('gfm gfm-epic has-tooltip')
    end
  end
end
