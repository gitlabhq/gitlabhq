import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/container_registry/explorer/components/details_page/delete_alert.vue';
import {
  DELETE_TAG_SUCCESS_MESSAGE,
  DELETE_TAG_ERROR_MESSAGE,
  DELETE_TAGS_SUCCESS_MESSAGE,
  DELETE_TAGS_ERROR_MESSAGE,
  ADMIN_GARBAGE_COLLECTION_TIP,
} from '~/packages_and_registries/container_registry/explorer/constants';

describe('Delete alert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLink = () => wrapper.findComponent(GlLink);

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, { stubs: { GlSprintf }, propsData });
  };

  describe('when deleteAlertType is null', () => {
    it('does not show the alert', () => {
      mountComponent();
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when deleteAlertType is not null', () => {
    describe('success states', () => {
      describe.each`
        deleteAlertType   | message
        ${'success_tag'}  | ${DELETE_TAG_SUCCESS_MESSAGE}
        ${'success_tags'} | ${DELETE_TAGS_SUCCESS_MESSAGE}
      `('when deleteAlertType is $deleteAlertType', ({ deleteAlertType, message }) => {
        it('alert exists', () => {
          mountComponent({ deleteAlertType });
          expect(findAlert().exists()).toBe(true);
        });

        describe('when the user is an admin', () => {
          beforeEach(() => {
            mountComponent({
              deleteAlertType,
              isAdmin: true,
              garbageCollectionHelpPagePath: 'foo',
            });
          });

          it(`alert title is ${message}`, () => {
            expect(findAlert().attributes('title')).toBe(message);
          });

          it('alert body contains admin tip', () => {
            expect(findAlert().text()).toMatchInterpolatedText(ADMIN_GARBAGE_COLLECTION_TIP);
          });

          it('alert body contains link', () => {
            const alertLink = findLink();
            expect(alertLink.exists()).toBe(true);
            expect(alertLink.attributes('href')).toBe('foo');
          });
        });

        describe('when the user is not an admin', () => {
          it('alert exist and text is appropriate', () => {
            mountComponent({ deleteAlertType });
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(message);
          });
        });
      });
    });
    describe('error states', () => {
      describe.each`
        deleteAlertType  | message
        ${'danger_tag'}  | ${DELETE_TAG_ERROR_MESSAGE}
        ${'danger_tags'} | ${DELETE_TAGS_ERROR_MESSAGE}
      `('when deleteAlertType is $deleteAlertType', ({ deleteAlertType, message }) => {
        it('alert exists', () => {
          mountComponent({ deleteAlertType });
          expect(findAlert().exists()).toBe(true);
        });

        describe('when the user is an admin', () => {
          it('alert exist and text is appropriate', () => {
            mountComponent({ deleteAlertType });
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(message);
          });
        });

        describe('when the user is not an admin', () => {
          it('alert exist and text is appropriate', () => {
            mountComponent({ deleteAlertType });
            expect(findAlert().exists()).toBe(true);
            expect(findAlert().text()).toBe(message);
          });
        });
      });
    });

    describe('dismissing alert', () => {
      it('GlAlert dismiss event triggers a change event', () => {
        mountComponent({ deleteAlertType: 'success_tags' });
        findAlert().vm.$emit('dismiss');
        expect(wrapper.emitted('change')).toEqual([[null]]);
      });
    });
  });
});
