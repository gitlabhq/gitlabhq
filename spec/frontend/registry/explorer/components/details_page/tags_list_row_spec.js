import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox, GlSprintf } from '@gitlab/ui';

import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import component from '~/registry/explorer/components/details_page/tags_list_row.vue';
import DeleteButton from '~/registry/explorer/components/delete_button.vue';
import DetailsRow from '~/registry/explorer/components/details_page/details_row.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
} from '~/registry/explorer/constants/index';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import { tagsListResponse } from '../../mock_data';
import { ListItem } from '../../stubs';

describe('tags list row', () => {
  let wrapper;
  const [tag] = [...tagsListResponse.data];

  const defaultProps = { tag, isDesktop: true, index: 0 };

  const findCheckbox = () => wrapper.find(GlFormCheckbox);
  const findName = () => wrapper.find('[data-testid="name"]');
  const findSize = () => wrapper.find('[data-testid="size"]');
  const findTime = () => wrapper.find('[data-testid="time"]');
  const findShortRevision = () => wrapper.find('[data-testid="digest"]');
  const findClipboardButton = () => wrapper.find(ClipboardButton);
  const findDeleteButton = () => wrapper.find(DeleteButton);
  const findTimeAgoTooltip = () => wrapper.find(TimeAgoTooltip);
  const findDetailsRows = () => wrapper.findAll(DetailsRow);
  const findPublishedDateDetail = () => wrapper.find('[data-testid="published-date-detail"]');
  const findManifestDetail = () => wrapper.find('[data-testid="manifest-detail"]');
  const findConfigurationDetail = () => wrapper.find('[data-testid="configuration-detail"]');

  const mountComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
        ListItem,
        DetailsRow,
      },
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('checkbox', () => {
    it('exists', () => {
      mountComponent();

      expect(findCheckbox().exists()).toBe(true);
    });

    it("does not exist when the row can't be deleted", () => {
      const customTag = { ...tag, destroy_path: '' };

      mountComponent({ ...defaultProps, tag: customTag });

      expect(findCheckbox().exists()).toBe(false);
    });

    it('is wired to the selected prop', () => {
      mountComponent({ ...defaultProps, selected: true });

      expect(findCheckbox().attributes('checked')).toBe('true');
    });

    it('when changed emit a select event', () => {
      mountComponent();

      findCheckbox().vm.$emit('change');

      expect(wrapper.emitted('select')).toEqual([[]]);
    });
  });

  describe('tag name', () => {
    it('exists', () => {
      mountComponent();

      expect(findName().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findName().text()).toBe(tag.name);
    });

    it('has a tooltip', () => {
      mountComponent();

      const tooltip = getBinding(findName().element, 'gl-tooltip');

      expect(tooltip.value.title).toBe(tag.name);
    });

    it('on mobile has mw-s class', () => {
      mountComponent({ ...defaultProps, isDesktop: false });

      expect(findName().classes('mw-s')).toBe(true);
    });
  });

  describe('clipboard button', () => {
    it('exist if tag.location exist', () => {
      mountComponent();

      expect(findClipboardButton().exists()).toBe(true);
    });

    it('is hidden if tag does not have a location', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, location: null } });

      expect(findClipboardButton().exists()).toBe(false);
    });

    it('has the correct props/attributes', () => {
      mountComponent();

      expect(findClipboardButton().attributes()).toMatchObject({
        text: 'location',
        title: 'location',
      });
    });
  });

  describe('size', () => {
    it('exists', () => {
      mountComponent();

      expect(findSize().exists()).toBe(true);
    });

    it('contains the total_size and layers', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, total_size: 1024 } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB · 10 layers');
    });

    it('when total_size is missing', () => {
      mountComponent();

      expect(findSize().text()).toMatchInterpolatedText('10 layers');
    });

    it('when layers are missing', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, total_size: 1024, layers: null } });

      expect(findSize().text()).toMatchInterpolatedText('1.00 KiB');
    });

    it('when there is 1 layer', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, layers: 1 } });

      expect(findSize().text()).toMatchInterpolatedText('1 layer');
    });
  });

  describe('time', () => {
    it('exists', () => {
      mountComponent();

      expect(findTime().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findTime().text()).toBe('Published');
    });

    it('contains time_ago_tooltip component', () => {
      mountComponent();

      expect(findTimeAgoTooltip().exists()).toBe(true);
    });

    it('pass the correct props to time ago tooltip', () => {
      mountComponent();

      expect(findTimeAgoTooltip().attributes()).toMatchObject({ time: tag.created_at });
    });
  });

  describe('digest', () => {
    it('exists', () => {
      mountComponent();

      expect(findShortRevision().exists()).toBe(true);
    });

    it('has the correct text', () => {
      mountComponent();

      expect(findShortRevision().text()).toMatchInterpolatedText('Digest: 1ab51d5');
    });
  });

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('has the correct props/attributes', () => {
      mountComponent();

      expect(findDeleteButton().attributes()).toMatchObject({
        title: REMOVE_TAG_BUTTON_TITLE,
        tooltiptitle: REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
        tooltipdisabled: 'true',
      });
    });

    it('is disabled when tag has no destroy path', () => {
      mountComponent({ ...defaultProps, tag: { ...tag, destroy_path: null } });

      expect(findDeleteButton().attributes('disabled')).toBe('true');
    });

    it('delete event emits delete', () => {
      mountComponent();

      findDeleteButton().vm.$emit('delete');

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });

  describe('details rows', () => {
    beforeEach(() => {
      mountComponent();

      return wrapper.vm.$nextTick();
    });

    it('has 3 details rows', () => {
      expect(findDetailsRows().length).toBe(3);
    });

    describe.each`
      name                       | finderFunction             | text                                                                                               | icon            | clipboard
      ${'published date detail'} | ${findPublishedDateDetail} | ${'Published to the bar image repository at 10:23 GMT+0000 on 2020-06-29'}                         | ${'clock'}      | ${false}
      ${'manifest detail'}       | ${findManifestDetail}      | ${'Manifest digest: sha256:1ab51d519f574b636ae7788051c60239334ae8622a9fd82a0cf7bae7786dfd5c'}      | ${'log'}        | ${true}
      ${'configuration detail'}  | ${findConfigurationDetail} | ${'Configuration digest: sha256:b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43'} | ${'cloud-gear'} | ${true}
    `('$name details row', ({ finderFunction, text, icon, clipboard }) => {
      it(`has ${text} as text`, () => {
        expect(finderFunction().text()).toMatchInterpolatedText(text);
      });

      it(`has the ${icon} icon`, () => {
        expect(finderFunction().props('icon')).toBe(icon);
      });

      it(`is ${clipboard} that clipboard button exist`, () => {
        expect(
          finderFunction()
            .find(ClipboardButton)
            .exists(),
        ).toBe(clipboard);
      });
    });
  });
});
