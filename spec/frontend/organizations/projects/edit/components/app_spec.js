import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/projects/edit/components/app.vue';

describe('OrganizationProjectsEditApp', () => {
  let wrapper;

  const defaultProvide = {
    project: {
      id: 1,
      name: 'Foo bar',
      fullName: 'Mock namespace / Foo bar',
      description: 'Mock description',
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
      wrapper.findByRole('heading', { name: 'Edit project: Mock namespace / Foo bar' }).exists(),
    ).toBe(true);
  });
});
