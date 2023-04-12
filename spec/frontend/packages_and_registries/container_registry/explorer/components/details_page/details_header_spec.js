import { GlDropdownItem, GlIcon, GlDropdown } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/details_header.vue';
import {
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
  UNFINISHED_STATUS,
  CLEANUP_DISABLED_TEXT,
  CLEANUP_DISABLED_TOOLTIP,
  CLEANUP_SCHEDULED_TOOLTIP,
  CLEANUP_ONGOING_TOOLTIP,
  CLEANUP_UNFINISHED_TOOLTIP,
  ROOT_IMAGE_TOOLTIP,
} from '~/packages_and_registries/container_registry/explorer/constants';
import getContainerRepositoryMetadata from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_container_repository_metadata.query.graphql';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { containerRepositoryMock, imageTagsCountMock } from '../../mock_data';

describe('Details Header', () => {
  let wrapper;
  let apolloProvider;

  const defaultImage = {
    ...containerRepositoryMock,
  };

  // set the date to Dec 4, 2020
  useFakeDate(2020, 11, 4);

  const findCreatedAndVisibility = () => wrapper.findByTestId('created-and-visibility');
  const findTitle = () => wrapper.findByTestId('title');
  const findTagsCount = () => wrapper.findByTestId('tags-count');
  const findCleanup = () => wrapper.findByTestId('cleanup');
  const findDeleteButton = () => wrapper.findComponent(GlDropdownItem);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findMenu = () => wrapper.findComponent(GlDropdown);
  const findSize = () => wrapper.findByTestId('image-size');

  const waitForMetadataItems = async () => {
    // Metadata items are printed by a loop in the title-area and it takes two ticks for them to be available
    await nextTick();
    await nextTick();
  };

  const mountComponent = ({
    propsData = { image: defaultImage },
    resolver = jest.fn().mockResolvedValue(imageTagsCountMock()),
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryMetadata, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(component, {
      apolloProvider,
      propsData,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        TitleArea,
        GlDropdown,
        GlDropdownItem,
      },
    });
  };

  afterEach(() => {
    // if we want to mix createMockApollo and manual mocks we need to reset everything
    apolloProvider = undefined;
  });

  describe('image name', () => {
    describe('missing image name', () => {
      beforeEach(() => {
        mountComponent({ propsData: { image: { ...defaultImage, name: '' } } });

        return waitForPromises();
      });

      it('root image shows project path name', () => {
        expect(findTitle().text()).toBe('gitlab-test');
      });

      it('has an icon', () => {
        expect(findInfoIcon().exists()).toBe(true);
        expect(findInfoIcon().props('name')).toBe('information-o');
      });

      it('has a tooltip', () => {
        const tooltip = getBinding(findInfoIcon().element, 'gl-tooltip');
        expect(tooltip.value).toBe(ROOT_IMAGE_TOOLTIP);
      });
    });

    describe('with image name present', () => {
      beforeEach(() => {
        mountComponent();

        return waitForPromises();
      });

      it('shows image.name', () => {
        expect(findTitle().text()).toContain('rails-12009');
      });

      it('has no icon', () => {
        expect(findInfoIcon().exists()).toBe(false);
      });
    });
  });

  describe('menu', () => {
    it.each`
      canDelete | disabled | isVisible
      ${true}   | ${false} | ${true}
      ${true}   | ${true}  | ${false}
      ${false}  | ${false} | ${false}
      ${false}  | ${true}  | ${false}
    `(
      'when canDelete is $canDelete and disabled is $disabled is $isVisible that the menu is visible',
      ({ canDelete, disabled, isVisible }) => {
        mountComponent({ propsData: { image: { ...defaultImage, canDelete }, disabled } });

        expect(findMenu().exists()).toBe(isVisible);
      },
    );

    describe('delete button', () => {
      it('exists', () => {
        mountComponent();

        expect(findDeleteButton().exists()).toBe(true);
      });

      it('has the correct text', () => {
        mountComponent();

        expect(findDeleteButton().text()).toBe('Delete image repository');
      });

      it('has the correct props', () => {
        mountComponent();

        expect(findDeleteButton().attributes()).toMatchObject(
          expect.objectContaining({
            variant: 'danger',
          }),
        );
      });

      it('emits the correct event', () => {
        mountComponent();

        findDeleteButton().vm.$emit('click');

        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });
  });

  describe('metadata items', () => {
    describe('tags count', () => {
      it('displays "-- tags" while loading', async () => {
        mountComponent();

        await waitForMetadataItems();

        expect(findTagsCount().props('text')).toBe('-- tags');
      });

      it('when there is more than one tag has the correct text', async () => {
        mountComponent();

        await waitForPromises();
        await waitForMetadataItems();

        expect(findTagsCount().props('text')).toBe('13 tags');
      });

      it('when there is one tag has the correct text', async () => {
        mountComponent({
          resolver: jest.fn().mockResolvedValue(imageTagsCountMock({ tagsCount: 1 })),
        });

        await waitForPromises();
        await waitForMetadataItems();

        expect(findTagsCount().props('text')).toBe('1 tag');
      });

      it('has the correct icon', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findTagsCount().props('icon')).toBe('tag');
      });
    });

    describe('size metadata item', () => {
      it('when size is not returned, it hides the item', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findSize().exists()).toBe(false);
      });

      it('when size is returned shows the item', async () => {
        const size = 1000;
        mountComponent({
          resolver: jest.fn().mockResolvedValue(imageTagsCountMock({ size })),
        });

        await waitForPromises();
        await waitForMetadataItems();

        expect(findSize().props()).toMatchObject({
          icon: 'disk',
          text: numberToHumanSize(size),
        });
      });
    });

    describe('cleanup metadata item', () => {
      it('has the correct icon', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCleanup().props('icon')).toBe('expire');
      });

      it('when cleanup is not scheduled', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCleanup().props()).toMatchObject({
          text: CLEANUP_DISABLED_TEXT,
          textTooltip: CLEANUP_DISABLED_TOOLTIP,
        });
      });

      it.each`
        status                | text                             | tooltip
        ${UNSCHEDULED_STATUS} | ${'Cleanup will run in 1 month'} | ${''}
        ${SCHEDULED_STATUS}   | ${'Cleanup pending'}             | ${CLEANUP_SCHEDULED_TOOLTIP}
        ${ONGOING_STATUS}     | ${'Cleanup in progress'}         | ${CLEANUP_ONGOING_TOOLTIP}
        ${UNFINISHED_STATUS}  | ${'Cleanup incomplete'}          | ${CLEANUP_UNFINISHED_TOOLTIP}
      `(
        'when the status is $status the text is $text and the tooltip is $tooltip',
        async ({ status, text, tooltip }) => {
          mountComponent({
            propsData: {
              image: {
                ...defaultImage,
                expirationPolicyCleanupStatus: status,
                project: {
                  containerExpirationPolicy: { enabled: true, nextRunAt: '2021-01-03T14:29:21Z' },
                },
              },
            },
          });
          await waitForMetadataItems();

          expect(findCleanup().props()).toMatchObject({
            text,
            textTooltip: tooltip,
          });
        },
      );
    });

    describe('visibility and created at', () => {
      it('has created text', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCreatedAndVisibility().props('text')).toBe('Created Nov 3, 2020 13:29');
      });

      describe('visibility icon', () => {
        it('shows an eye when the project is public', async () => {
          mountComponent();
          await waitForMetadataItems();

          expect(findCreatedAndVisibility().props('icon')).toBe('eye');
        });
        it('shows an eye slashed when the project is not public', async () => {
          mountComponent({
            propsData: { image: { ...defaultImage, project: { visibility: 'private' } } },
          });
          await waitForMetadataItems();

          expect(findCreatedAndVisibility().props('icon')).toBe('eye-slash');
        });
      });
    });
  });
});
