import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import waitForPromises from 'helpers/wait_for_promises';
import component from '~/registry/explorer/components/details_page/details_header.vue';
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
  ROOT_IMAGE_TEXT,
  ROOT_IMAGE_TOOLTIP,
} from '~/registry/explorer/constants';
import getContainerRepositoryTagCountQuery from '~/registry/explorer/graphql/queries/get_container_repository_tags_count.query.graphql';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { imageTagsCountMock } from '../../mock_data';

describe('Details Header', () => {
  let wrapper;
  let apolloProvider;
  let localVue;

  const defaultImage = {
    name: 'foo',
    updatedAt: '2020-11-03T13:29:21Z',
    canDelete: true,
    project: {
      visibility: 'public',
      containerExpirationPolicy: {
        enabled: false,
      },
    },
  };

  // set the date to Dec 4, 2020
  useFakeDate(2020, 11, 4);
  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);

  const findLastUpdatedAndVisibility = () => findByTestId('updated-and-visibility');
  const findTitle = () => findByTestId('title');
  const findTagsCount = () => findByTestId('tags-count');
  const findCleanup = () => findByTestId('cleanup');
  const findDeleteButton = () => wrapper.find(GlButton);
  const findInfoIcon = () => wrapper.find(GlIcon);

  const waitForMetadataItems = async () => {
    // Metadata items are printed by a loop in the title-area and it takes two ticks for them to be available
    await wrapper.vm.$nextTick();
    await wrapper.vm.$nextTick();
  };

  const mountComponent = ({
    propsData = { image: defaultImage },
    resolver = jest.fn().mockResolvedValue(imageTagsCountMock()),
    $apollo = undefined,
  } = {}) => {
    const mocks = {};

    if ($apollo) {
      mocks.$apollo = $apollo;
    } else {
      localVue = createLocalVue();
      localVue.use(VueApollo);

      const requestHandlers = [[getContainerRepositoryTagCountQuery, resolver]];
      apolloProvider = createMockApollo(requestHandlers);
    }

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      propsData,
      directives: {
        GlTooltip: createMockDirective(),
      },
      mocks,
      stubs: {
        TitleArea,
      },
    });
  };

  afterEach(() => {
    // if we want to mix createMockApollo and manual mocks we need to reset everything
    wrapper.destroy();
    apolloProvider = undefined;
    localVue = undefined;
    wrapper = null;
  });

  describe('image name', () => {
    describe('missing image name', () => {
      beforeEach(() => {
        mountComponent({ propsData: { image: { ...defaultImage, name: '' } } });

        return waitForPromises();
      });

      it('root image ', () => {
        expect(findTitle().text()).toBe(ROOT_IMAGE_TEXT);
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

      it('shows image.name ', () => {
        expect(findTitle().text()).toContain('foo');
      });

      it('has no icon', () => {
        expect(findInfoIcon().exists()).toBe(false);
      });
    });
  });

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

      expect(findDeleteButton().props()).toMatchObject({
        variant: 'danger',
        disabled: false,
      });
    });

    it('emits the correct event', () => {
      mountComponent();

      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });

    it.each`
      canDelete | disabled | isDisabled
      ${true}   | ${false} | ${false}
      ${true}   | ${true}  | ${true}
      ${false}  | ${false} | ${true}
      ${false}  | ${true}  | ${true}
    `(
      'when canDelete is $canDelete and disabled is $disabled is $isDisabled that the button is disabled',
      ({ canDelete, disabled, isDisabled }) => {
        mountComponent({ propsData: { image: { ...defaultImage, canDelete }, disabled } });

        expect(findDeleteButton().props('disabled')).toBe(isDisabled);
      },
    );
  });

  describe('metadata items', () => {
    describe('tags count', () => {
      it('displays "-- tags" while loading', async () => {
        // here we are forced to mock apollo because `waitForMetadataItems` waits
        // for two ticks, de facto allowing the promise to resolve, so there is
        // no way to catch the component as both rendered and in loading state
        mountComponent({ $apollo: { queries: { containerRepository: { loading: true } } } });

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

    describe('cleanup metadata item', () => {
      it('has the correct icon', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findCleanup().props('icon')).toBe('expire');
      });

      it('when the expiration policy is disabled', async () => {
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

    describe('visibility and updated at ', () => {
      it('has last updated text', async () => {
        mountComponent();
        await waitForMetadataItems();

        expect(findLastUpdatedAndVisibility().props('text')).toBe('Last updated 1 month ago');
      });

      describe('visibility icon', () => {
        it('shows an eye when the project is public', async () => {
          mountComponent();
          await waitForMetadataItems();

          expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye');
        });
        it('shows an eye slashed when the project is not public', async () => {
          mountComponent({
            propsData: { image: { ...defaultImage, project: { visibility: 'private' } } },
          });
          await waitForMetadataItems();

          expect(findLastUpdatedAndVisibility().props('icon')).toBe('eye-slash');
        });
      });
    });
  });
});
