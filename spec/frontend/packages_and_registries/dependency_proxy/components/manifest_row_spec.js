import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import Component from '~/packages_and_registries/dependency_proxy/components/manifest_row.vue';
import { MANIFEST_PENDING_DESTRUCTION_STATUS } from '~/packages_and_registries/dependency_proxy/constants';
import { proxyData, proxyManifests } from 'jest/packages_and_registries/dependency_proxy/mock_data';

describe('Manifest Row', () => {
  let wrapper;

  const defaultProps = {
    dependencyProxyImagePrefix: proxyData().dependencyProxyImagePrefix,
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

  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findListItem = () => wrapper.findComponent(ListItem);
  const findCachedMessages = () => wrapper.findByTestId('cached-message');
  const findDigest = () => wrapper.findByTestId('manifest-row-short-digest');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeagoTooltip);
  const findStatus = () => wrapper.findByTestId('status');

  describe('With a manifest on the DEFAULT status', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has a list item', () => {
      expect(findListItem().exists()).toBe(true);
    });

    it('displays the name with tag & digest', () => {
      expect(wrapper.text()).toContain('alpine:latest');
      expect(findDigest().text()).toMatchInterpolatedText('Digest: 995efde');
    });

    it('displays the name & digest for manifests that contain digest in image name', () => {
      createComponent({
        ...defaultProps,
        manifest: proxyManifests()[1],
      });
      expect(wrapper.text()).toContain('alpine');
      expect(findDigest().text()).toMatchInterpolatedText('Digest: e95efde');
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

  describe('clipboard button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('exists', () => {
      expect(findClipboardButton().exists()).toBe(true);
    });

    it('passes the correct title prop', () => {
      expect(findClipboardButton().attributes('title')).toBe(Component.i18n.copyImagePathTitle);
    });

    it('has the correct copy text when image name contains tag name', () => {
      expect(findClipboardButton().attributes('text')).toBe(
        'gdk.test:3000/private-group/dependency_proxy/containers/alpine:latest',
      );
    });

    it('has the correct copy text when image name contains digest', () => {
      createComponent({
        ...defaultProps,
        manifest: proxyManifests()[1],
      });

      expect(findClipboardButton().attributes('text')).toBe(
        'gdk.test:3000/private-group/dependency_proxy/containers/alpine@sha256:e95efde2e81b21d1ea7066aa77a59298a62a9e9fbb4b77f36c189774ec9b1089',
      );
    });
  });
});
