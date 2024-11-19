import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SoloOwnedOrganizationsMessage from '~/admin/users/components/solo_owned_organizations_message.vue';
import {
  oneSoloOwnedOrganization,
  twoSoloOwnedOrganizations,
  multipleSoloOwnedOrganizations,
  multipleWithOneExtraSoloOwnedOrganizations,
  multipleWithExtrasSoloOwnedOrganizations,
} from '../mock_data';

describe('SoloOwnedOrganizationsMessage', () => {
  let wrapper;

  function createComponent({ propsData = {} } = {}) {
    wrapper = shallowMountExtended(SoloOwnedOrganizationsMessage, {
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  }

  const findLinks = () => wrapper.findAllComponents(GlLink);

  it.each`
    organizations                                 | expectedMessage
    ${oneSoloOwnedOrganization}                   | ${'Organizations must have at least one owner. To delete the user, first assign a new owner to Foo 0.'}
    ${twoSoloOwnedOrganizations}                  | ${'Organizations must have at least one owner. To delete the user, first assign a new owner to Foo 0 and Foo 1.'}
    ${multipleSoloOwnedOrganizations}             | ${'Organizations must have at least one owner. To delete the user, first assign a new owner to Foo 0, Foo 1, and Foo 2.'}
    ${multipleWithOneExtraSoloOwnedOrganizations} | ${'Organizations must have at least one owner. To delete the user, first assign a new owner to Foo 0, Foo 1, Foo 2, Foo 3, Foo 4, Foo 5, Foo 6, Foo 7, Foo 8, Foo 9, and 1 other Organization.'}
    ${multipleWithExtrasSoloOwnedOrganizations}   | ${'Organizations must have at least one owner. To delete the user, first assign a new owner to Foo 0, Foo 1, Foo 2, Foo 3, Foo 4, Foo 5, Foo 6, Foo 7, Foo 8, Foo 9, and 2 other Organizations.'}
  `('renders expected message', ({ organizations, expectedMessage }) => {
    createComponent({ propsData: { organizations } });

    expect(wrapper.text()).toMatchInterpolatedText(expectedMessage);
  });

  it('renders organizations as links', () => {
    createComponent({ propsData: { organizations: multipleSoloOwnedOrganizations } });

    const links = findLinks();

    expect(links.at(0).attributes('href')).toBe('http://gdk.test:3000/-/organizations/foo-0');
    expect(links.at(0).text()).toBe('Foo 0');

    expect(links.at(1).attributes('href')).toBe('http://gdk.test:3000/-/organizations/foo-1');
    expect(links.at(1).text()).toBe('Foo 1');

    expect(links.at(2).attributes('href')).toBe('http://gdk.test:3000/-/organizations/foo-2');
    expect(links.at(2).text()).toBe('Foo 2');
  });
});
