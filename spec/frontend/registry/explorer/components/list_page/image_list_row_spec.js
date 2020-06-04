import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import Component from '~/registry/explorer/components/list_page/image_list_row.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import {
  ROW_SCHEDULED_FOR_DELETION,
  LIST_DELETE_BUTTON_DISABLED,
} from '~/registry/explorer/constants';
import { RouterLink } from '../../stubs';
import { imagesListResponse } from '../../mock_data';

describe('Image List Row', () => {
  let wrapper;
  const item = imagesListResponse.data[0];
  const findDeleteBtn = () => wrapper.find('[data-testid="deleteImageButton"]');
  const findDetailsLink = () => wrapper.find('[data-testid="detailsLink"]');
  const findTagsCount = () => wrapper.find('[data-testid="tagsCount"]');
  const findDeleteButtonWrapper = () => wrapper.find('[data-testid="deleteButtonWrapper"]');
  const findClipboardButton = () => wrapper.find(ClipboardButton);

  const mountComponent = props => {
    wrapper = shallowMount(Component, {
      stubs: {
        RouterLink,
        GlSprintf,
      },
      propsData: {
        item,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('main tooltip', () => {
    it(`the title is ${ROW_SCHEDULED_FOR_DELETION}`, () => {
      mountComponent();
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(ROW_SCHEDULED_FOR_DELETION);
    });

    it('is disabled when item is being deleted', () => {
      mountComponent({ item: { ...item, deleting: true } });
      const tooltip = getBinding(wrapper.element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBe(false);
    });
  });

  describe('image title and path', () => {
    it('contains a link to the details page', () => {
      mountComponent();
      const link = findDetailsLink();
      expect(link.html()).toContain(item.path);
      expect(link.props('to').name).toBe('details');
    });

    it('contains a clipboard button', () => {
      mountComponent();
      const button = findClipboardButton();
      expect(button.exists()).toBe(true);
      expect(button.props('text')).toBe(item.location);
      expect(button.props('title')).toBe(item.location);
    });
  });

  describe('delete button wrapper', () => {
    it('has a tooltip', () => {
      mountComponent();
      const tooltip = getBinding(findDeleteButtonWrapper().element, 'gl-tooltip');
      expect(tooltip).toBeDefined();
      expect(tooltip.value.title).toBe(LIST_DELETE_BUTTON_DISABLED);
    });
    it('tooltip is enabled when destroy_path is falsy', () => {
      mountComponent({ item: { ...item, destroy_path: null } });
      const tooltip = getBinding(findDeleteButtonWrapper().element, 'gl-tooltip');
      expect(tooltip.value.disabled).toBeFalsy();
    });
  });

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('emits a delete event', () => {
      mountComponent();
      findDeleteBtn().vm.$emit('click');
      expect(wrapper.emitted('delete')).toEqual([[item]]);
    });

    it.each`
      destroy_path | deleting | state
      ${null}      | ${null}  | ${'true'}
      ${null}      | ${true}  | ${'true'}
      ${'foo'}     | ${true}  | ${'true'}
      ${'foo'}     | ${false} | ${undefined}
    `(
      'disabled is $state when destroy_path is $destroy_path and deleting is $deleting',
      ({ destroy_path, deleting, state }) => {
        mountComponent({ item: { ...item, destroy_path, deleting } });
        expect(findDeleteBtn().attributes('disabled')).toBe(state);
      },
    );
  });

  describe('tags count', () => {
    it('exists', () => {
      mountComponent();
      expect(findTagsCount().exists()).toBe(true);
    });

    it('contains a tag icon', () => {
      mountComponent();
      const icon = findTagsCount().find(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('tag');
    });

    describe('tags count text', () => {
      it('with one tag in the image', () => {
        mountComponent({ item: { ...item, tags_count: 1 } });
        expect(findTagsCount().text()).toMatchInterpolatedText('1 Tag');
      });
      it('with more than one tag in the image', () => {
        mountComponent({ item: { ...item, tags_count: 3 } });
        expect(findTagsCount().text()).toMatchInterpolatedText('3 Tags');
      });
    });
  });
});
