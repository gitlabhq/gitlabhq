import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
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
  const findLastPublishedAt = () => wrapper.findByTestId('last-published-at');
  const findTitle = () => wrapper.findByTestId('title');
  const findTagsCount = () => wrapper.findByTestId('tags-count');
  const findCleanup = () => wrapper.findByTestId('cleanup');
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findMenu = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSize = () => wrapper.findByTestId('image-size');

  const defaultProvide = {
    config: {
      isMetadataDatabaseEnabled: true,
    },
  };

  const mountComponent = ({
    propsData = { image: defaultImage },
    provide = defaultProvide,
    resolver = jest.fn().mockResolvedValue(imageTagsCountMock()),
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[getContainerRepositoryMetadata, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(component, {
      apolloProvider,
      propsData,
      provide,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  afterEach(() => {
    // if we want to mix createMockApollo and manual mocks we need to reset everything
    apolloProvider = undefined;
  });

  it('calls the resolver with the correct arguments', () => {
    const resolver = jest.fn().mockResolvedValue(imageTagsCountMock());
    mountComponent({ resolver });

    expect(resolver).toHaveBeenCalledWith({
      id: defaultImage.id,
      metadataDatabaseEnabled: true,
    });
  });

  describe('when metadata database is disabled', () => {
    const resolver = jest.fn().mockResolvedValue(imageTagsCountMock());

    beforeEach(() => {
      mountComponent({
        provide: {
          ...defaultProvide,
          config: {
            isMetadataDatabaseEnabled: false,
          },
        },
        resolver,
      });
    });

    it('calls the resolver with the correct arguments', () => {
      expect(resolver).toHaveBeenCalledWith({
        id: defaultImage.id,
        metadataDatabaseEnabled: false,
      });
    });
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
      destroyContainerRepository | disabled | isVisible
      ${true}                    | ${false} | ${true}
      ${true}                    | ${true}  | ${false}
      ${false}                   | ${false} | ${false}
      ${false}                   | ${true}  | ${false}
    `(
      'when userPermissions.destroyContainerRepository is $destroyContainerRepository and disabled is $disabled is $isVisible that the menu is visible',
      ({ destroyContainerRepository, disabled, isVisible }) => {
        mountComponent({
          propsData: {
            image: { ...defaultImage, userPermissions: { destroyContainerRepository } },
            disabled,
          },
        });

        expect(findMenu().exists()).toBe(isVisible);
      },
    );

    it('has the correct props', () => {
      mountComponent();

      expect(findMenu().props()).toMatchObject({
        category: 'tertiary',
        icon: 'ellipsis_v',
        placement: 'bottom-end',
        textSrOnly: true,
        noCaret: true,
        toggleText: 'More actions',
      });
    });

    describe('delete item', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('exists', () => {
        expect(findDeleteButton().exists()).toBe(true);
      });

      it('has the correct text', () => {
        expect(findDeleteButton().text()).toBe('Delete image repository');
      });

      it('emits the correct event', () => {
        findDeleteButton().vm.$emit('action');

        expect(wrapper.emitted('delete')).toHaveLength(1);
      });
    });
  });

  describe('metadata items', () => {
    describe('tags count', () => {
      it('displays "-- tags" while loading', () => {
        mountComponent();

        expect(findTagsCount().props('text')).toBe('-- tags');
      });

      it('when there is more than one tag has the correct text', async () => {
        mountComponent();

        await waitForPromises();

        expect(findTagsCount().props('text')).toBe('13 tags');
      });

      it('when there is one tag has the correct text', async () => {
        mountComponent({
          resolver: jest.fn().mockResolvedValue(imageTagsCountMock({ tagsCount: 1 })),
        });

        await waitForPromises();

        expect(findTagsCount().props('text')).toBe('1 tag');
      });

      it('has the correct icon', () => {
        mountComponent();

        expect(findTagsCount().props('icon')).toBe('tag');
      });
    });

    describe('size metadata item', () => {
      it('when size is not returned, it hides the item', () => {
        mountComponent();

        expect(findSize().exists()).toBe(false);
      });

      it('when size is returned shows the item', async () => {
        const size = 1000;
        mountComponent({
          resolver: jest.fn().mockResolvedValue(imageTagsCountMock({ size })),
        });

        await waitForPromises();

        expect(findSize().props()).toMatchObject({
          icon: 'disk',
          text: numberToHumanSize(size),
          textTooltip: 'Includes both tagged and untagged images',
        });
      });
    });

    describe('cleanup metadata item', () => {
      it('when cleanup is not scheduled has the right icon and props', () => {
        mountComponent();

        expect(findCleanup().props()).toMatchObject({
          icon: 'expire',
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
        ({ status, text, tooltip }) => {
          mountComponent({
            propsData: {
              image: {
                ...defaultImage,
                expirationPolicyCleanupStatus: status,
                project: {
                  containerTagsExpirationPolicy: {
                    enabled: true,
                    nextRunAt: '2021-01-03T14:29:21Z',
                  },
                },
              },
            },
          });

          expect(findCleanup().props()).toMatchObject({
            text,
            textTooltip: tooltip,
          });
        },
      );
    });

    describe('visibility and created at', () => {
      it('has created text', () => {
        mountComponent();

        expect(findCreatedAndVisibility().props('text')).toBe('Created Nov 3, 2020 13:29');
      });

      describe('visibility icon', () => {
        it('shows an eye when the project is public', () => {
          mountComponent();

          expect(findCreatedAndVisibility().props('icon')).toBe('eye');
        });
        it('shows an eye slashed when the project is not public', () => {
          mountComponent({
            propsData: { image: { ...defaultImage, project: { visibility: 'private' } } },
          });

          expect(findCreatedAndVisibility().props('icon')).toBe('eye-slash');
        });
      });
    });

    describe('last published at', () => {
      it('is rendered when exists', async () => {
        mountComponent();

        await waitForPromises();

        expect(findLastPublishedAt().props()).toMatchObject({
          icon: 'calendar',
          text: 'Last published at Nov 5, 2020 13:29',
        });
      });

      it('is hidden when null', async () => {
        mountComponent({
          resolver: jest.fn().mockResolvedValue(imageTagsCountMock({ lastPublishedAt: null })),
        });

        await waitForPromises();
        expect(findLastPublishedAt().exists()).toBe(false);
      });
    });
  });

  describe('badge "protected"', () => {
    const createComponentForBadgeProtected = async ({ imageProtectionRuleExists = true } = {}) => {
      await mountComponent({
        propsData: {
          image: {
            ...defaultImage,
            protectionRuleExists: imageProtectionRuleExists,
          },
        },
        provide: {
          ...defaultProvide,
        },
      });
    };

    const findProtectedBadge = () => wrapper.findComponent(ProtectedBadge);

    describe('when a protection rule exists for the given package', () => {
      it('shows badge', () => {
        createComponentForBadgeProtected();

        expect(findProtectedBadge().exists()).toBe(true);
        expect(findProtectedBadge().props('tooltipText')).toBe(
          'A protection rule exists for this container repository.',
        );
      });
    });

    describe('when no protection rule exists for the given package', () => {
      it('does not show badge', () => {
        createComponentForBadgeProtected({ imageProtectionRuleExists: false });

        expect(findProtectedBadge().exists()).toBe(false);
      });
    });
  });
});
