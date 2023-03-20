import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Component from '~/packages_and_registries/dependency_proxy/components/manifest_row.vue';
import { MANIFEST_PENDING_DESTRUCTION_STATUS } from '~/packages_and_registries/dependency_proxy/constants';
import { proxyManifests } from 'jest/packages_and_registries/dependency_proxy/mock_data';

describe('Manifest Row', () => {
  let wrapper;

  const defaultProps = {
    manifest: proxyManifests()[0],
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMountExtended(Component, {
      propsData,
      stubs: {
        GlSprintf,
        TimeagoTooltip,
        ListItem,
      },
    });
  };

  const findListItem = () => wrapper.findComponent(ListItem);
  const findCachedMessages = () => wrapper.findByTestId('cached-message');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findStatus = () => wrapper.findByTestId('status');

  describe('With a manifest on the DEFAULT status', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has a list item', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('displays the name', () => {
      expect(wrapper.text()).toContain('alpine');
    });

    it('displays the version', () => {
      expect(wrapper.text()).toContain('latest');
    });

    it('displays the cached time', () => {
      expect(findCachedMessages().text()).toContain('Cached');
    });

    it('has a time ago tooltip component', () => {
      expect(findTimeAgoTooltip().props()).toMatchObject({
        time: defaultProps.manifest.createdAt,
      });
    });

    it('does not have a status element displayed', () => {
      expect(findStatus().exists()).toBe(false);
    });
  });

  describe('With a manifest on the PENDING_DESTRUCTION_STATUS', () => {
    const pendingDestructionManifest = {
      manifest: {
        ...defaultProps.manifest,
        status: MANIFEST_PENDING_DESTRUCTION_STATUS,
      },
    };

    beforeEach(() => {
      createComponent(pendingDestructionManifest);
    });

    it('has a list item', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('has a status element displayed', () => {
      expect(findStatus().exists()).toBe(true);
      expect(findStatus().text()).toBe('Scheduled for deletion');
    });
  });
});
