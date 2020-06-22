import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Component from '~/registry/explorer/components/list_page/image_list_row.vue';
import ListItem from '~/registry/explorer/components/list_item.vue';
import DeleteButton from '~/registry/explorer/components/delete_button.vue';
import {
  ROW_SCHEDULED_FOR_DELETION,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
} from '~/registry/explorer/constants';
import { RouterLink } from '../../stubs';
import { imagesListResponse } from '../../mock_data';

describe('Image List Row', () => {
  let wrapper;
  const item = imagesListResponse.data[0];

  const findDetailsLink = () => wrapper.find('[data-testid="detailsLink"]');
  const findTagsCount = () => wrapper.find('[data-testid="tagsCount"]');
  const findDeleteBtn = () => wrapper.find(DeleteButton);
  const findClipboardButton = () => wrapper.find(ClipboardButton);

  const mountComponent = props => {
    wrapper = shallowMount(Component, {
      stubs: {
        RouterLink,
        GlSprintf,
        ListItem,
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

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();
      expect(findDeleteBtn().attributes()).toMatchObject({
        title: REMOVE_REPOSITORY_LABEL,
        tooltipdisabled: `${Boolean(item.destroy_path)}`,
        tooltiptitle: LIST_DELETE_BUTTON_DISABLED,
      });
    });

    it('emits a delete event', () => {
      mountComponent();
      findDeleteBtn().vm.$emit('delete');
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
