import { shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import { GlLink } from '@gitlab/ui';
import ReleaseBlockHeader from '~/releases/components/release_block_header.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { release as originalRelease } from '../mock_data';

describe('Release block header', () => {
  let wrapper;
  let release;

  const factory = (releaseUpdates = {}) => {
    wrapper = shallowMount(ReleaseBlockHeader, {
      propsData: {
        release: merge({}, release, releaseUpdates),
      },
    });
  };

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease, { deep: true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeader = () => wrapper.find('h2');
  const findHeaderLink = () => findHeader().find(GlLink);

  describe('when _links.self is provided', () => {
    beforeEach(() => {
      factory();
    });

    it('renders the title as a link', () => {
      const link = findHeaderLink();

      expect(link.text()).toBe(release.name);
      expect(link.attributes('href')).toBe(release.Links.self);
    });
  });

  describe('when _links.self is missing', () => {
    beforeEach(() => {
      factory({ Links: { self: null } });
    });

    it('renders the title as text', () => {
      expect(findHeader().text()).toBe(release.name);
      expect(findHeaderLink().exists()).toBe(false);
    });
  });
});
