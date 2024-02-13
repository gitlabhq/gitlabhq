import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StorageTypeHelpLink from '~/usage_quotas/storage/components/storage_type_help_link.vue';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';

let wrapper;

const createComponent = ({ props = {} } = {}) => {
  wrapper = shallowMount(StorageTypeHelpLink, {
    propsData: {
      helpLinks: storageTypeHelpPaths,
      ...props,
    },
  });
};

const findLink = () => wrapper.findComponent(GlLink);

describe('StorageTypeHelpLink', () => {
  describe('Storage type w/ link', () => {
    describe.each(Object.entries(storageTypeHelpPaths))('%s', (storageType, url) => {
      beforeEach(() => {
        createComponent({
          props: {
            storageType,
          },
        });
      });

      it('will have proper href', () => {
        expect(findLink().attributes('href')).toBe(url);
      });
    });
  });

  describe('Storage type w/o help link', () => {
    beforeEach(() => {
      createComponent({
        props: {
          storageType: 'Yellow Submarine',
        },
      });
    });

    it('will not have a href', () => {
      expect(findLink().attributes('href')).toBe(undefined);
    });
  });
});
