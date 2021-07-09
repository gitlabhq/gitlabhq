import { GlIcon, GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import DeleteButton from '~/registry/explorer/components/delete_button.vue';
import CleanupStatus from '~/registry/explorer/components/list_page/cleanup_status.vue';
import Component from '~/registry/explorer/components/list_page/image_list_row.vue';
import {
  ROW_SCHEDULED_FOR_DELETION,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  IMAGE_DELETE_SCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ROOT_IMAGE_TEXT,
} from '~/registry/explorer/constants';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { imagesListResponse } from '../../mock_data';
import { RouterLink } from '../../stubs';

describe('Image List Row', () => {
  let wrapper;
  const [item] = imagesListResponse;

  const findDetailsLink = () => wrapper.find('[data-testid="details-link"]');
  const findTagsCount = () => wrapper.find('[data-testid="tags-count"]');
  const findDeleteBtn = () => wrapper.findComponent(DeleteButton);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findCleanupStatus = () => wrapper.findComponent(CleanupStatus);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findListItemComponent = () => wrapper.findComponent(ListItem);

  const mountComponent = (props) => {
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

  describe('list item component', () => {
    describe('tooltip', () => {
      it(`the title is ${ROW_SCHEDULED_FOR_DELETION}`, () => {
        mountComponent();

        const tooltip = getBinding(wrapper.element, 'gl-tooltip');
        expect(tooltip).toBeDefined();
        expect(tooltip.value.title).toBe(ROW_SCHEDULED_FOR_DELETION);
      });

      it('is disabled when item is being deleted', () => {
        mountComponent({ item: { ...item, status: IMAGE_DELETE_SCHEDULED_STATUS } });

        const tooltip = getBinding(wrapper.element, 'gl-tooltip');
        expect(tooltip.value.disabled).toBe(false);
      });
    });

    it('is disabled when the item is in deleting status', () => {
      mountComponent({ item: { ...item, status: IMAGE_DELETE_SCHEDULED_STATUS } });

      expect(findListItemComponent().props('disabled')).toBe(true);
    });
  });

  describe('image title and path', () => {
    it('contains a link to the details page', () => {
      mountComponent();

      const link = findDetailsLink();
      expect(link.text()).toBe(item.path);
      expect(findDetailsLink().props('to')).toMatchObject({
        name: 'details',
        params: {
          id: getIdFromGraphQLId(item.id),
        },
      });
    });

    it(`when the image has no name appends ${ROOT_IMAGE_TEXT} to the path`, () => {
      mountComponent({ item: { ...item, name: '' } });

      expect(findDetailsLink().text()).toBe(`${item.path}/ ${ROOT_IMAGE_TEXT}`);
    });

    it('contains a clipboard button', () => {
      mountComponent();
      const button = findClipboardButton();
      expect(button.exists()).toBe(true);
      expect(button.props('text')).toBe(item.location);
      expect(button.props('title')).toBe(item.location);
    });

    describe('cleanup status component', () => {
      it.each`
        expirationPolicyCleanupStatus | shown
        ${null}                       | ${false}
        ${SCHEDULED_STATUS}           | ${true}
      `(
        'when expirationPolicyCleanupStatus is $expirationPolicyCleanupStatus it is $shown that the component exists',
        ({ expirationPolicyCleanupStatus, shown }) => {
          mountComponent({ item: { ...item, expirationPolicyCleanupStatus } });

          expect(findCleanupStatus().exists()).toBe(shown);

          if (shown) {
            expect(findCleanupStatus().props()).toMatchObject({
              status: expirationPolicyCleanupStatus,
            });
          }
        },
      );
    });

    describe('when the item is deleting', () => {
      beforeEach(() => {
        mountComponent({ item: { ...item, status: IMAGE_DELETE_SCHEDULED_STATUS } });
      });

      it('the router link is disabled', () => {
        // we check the event prop as is the only workaround to disable a router link
        expect(findDetailsLink().props('event')).toBe('');
      });
      it('the clipboard button is disabled', () => {
        expect(findClipboardButton().attributes('disabled')).toBe('true');
      });
    });
  });

  describe('delete button', () => {
    it('exists', () => {
      mountComponent();
      expect(findDeleteBtn().exists()).toBe(true);
    });

    it('has the correct props', () => {
      mountComponent();

      expect(findDeleteBtn().props()).toMatchObject({
        title: REMOVE_REPOSITORY_LABEL,
        tooltipDisabled: item.canDelete,
        tooltipTitle: LIST_DELETE_BUTTON_DISABLED,
      });
    });

    it('emits a delete event', () => {
      mountComponent();

      findDeleteBtn().vm.$emit('delete');
      expect(wrapper.emitted('delete')).toEqual([[item]]);
    });

    it.each`
      canDelete | status                           | state
      ${false}  | ${''}                            | ${true}
      ${false}  | ${IMAGE_DELETE_SCHEDULED_STATUS} | ${true}
      ${true}   | ${IMAGE_DELETE_SCHEDULED_STATUS} | ${true}
      ${true}   | ${''}                            | ${false}
    `(
      'disabled is $state when canDelete is $canDelete and status is $status',
      ({ canDelete, status, state }) => {
        mountComponent({ item: { ...item, canDelete, status } });

        expect(findDeleteBtn().props('disabled')).toBe(state);
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

    describe('loading state', () => {
      it('shows a loader when metadataLoading is true', () => {
        mountComponent({ metadataLoading: true });

        expect(findSkeletonLoader().exists()).toBe(true);
      });

      it('hides the tags count while loading', () => {
        mountComponent({ metadataLoading: true });

        expect(findTagsCount().exists()).toBe(false);
      });
    });

    describe('tags count text', () => {
      it('with one tag in the image', () => {
        mountComponent({ item: { ...item, tagsCount: 1 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('1 Tag');
      });
      it('with more than one tag in the image', () => {
        mountComponent({ item: { ...item, tagsCount: 3 } });

        expect(findTagsCount().text()).toMatchInterpolatedText('3 Tags');
      });
    });
  });
});
