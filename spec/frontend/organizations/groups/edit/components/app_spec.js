import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/groups/edit/components/app.vue';

describe('OrganizationGroupsEditApp', () => {
  let wrapper;

  const defaultProvide = {
    group: {
      fullName: 'Mock namespace / Foo bar',
    },
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      provide: defaultProvide,
      stubs: {
        GlSprintf,
      },
    });
  };

  it('renders page title', () => {
    createComponent();

    expect(
      wrapper.findByRole('heading', { name: 'Edit group: Mock namespace / Foo bar' }).exists(),
    ).toBe(true);
  });
});
