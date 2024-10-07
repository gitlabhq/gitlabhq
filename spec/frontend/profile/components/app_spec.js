import Vue from 'vue';
import VueRouter from 'vue-router';
import UserProfileApp from '~/profile/components/app.vue';
import { createRouter } from '~/profile';
import { USER_PROFILE_ROUTE_NAME_DEFAULT } from '~/profile/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ProfileTabs from '~/profile/components/profile_tabs.vue';

Vue.use(VueRouter);

describe('UserProfileApp', () => {
  let wrapper;

  const createComponent = async ({
    route = { name: USER_PROFILE_ROUTE_NAME_DEFAULT, params: { user: 'root' } },
  } = {}) => {
    const router = createRouter();

    wrapper = mountExtended(UserProfileApp, {
      stubs: {
        MountingPortal: true,
        ProfileTabs: true,
      },
      router,
    });

    await router.push(route);
  };

  describe.each`
    routeName                          | expectedComponent
    ${USER_PROFILE_ROUTE_NAME_DEFAULT} | ${ProfileTabs}
  `('when route name is `$routeName`', ({ routeName, expectedComponent }) => {
    it(`renders \`${expectedComponent.name}\` component`, async () => {
      await createComponent({ route: { name: routeName, params: { user: 'root' } } });

      expect(wrapper.findComponent(expectedComponent).exists()).toBe(true);
    });
  });
});
