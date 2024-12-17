import { mountExtended } from 'helpers/vue_test_utils_helper';
import ForksButton from '~/forks/components/forks_button.vue';

describe('ForksButton', () => {
  let wrapper;

  const findForkButton = () => wrapper.findByTestId('fork-button');
  const findForksCountButton = () => wrapper.findByTestId('forks-count');

  const mountComponent = ({ injections } = {}) => {
    wrapper = mountExtended(ForksButton, {
      provide: {
        forksCount: 10,
        projectForksUrl: '/project/forks',
        userForkUrl: '/user/fork',
        newForkUrl: '/new/fork',
        canReadCode: true,
        canForkProject: true,
        ...injections,
      },
    });
  };

  describe('forks count button', () => {
    it('renders the correct number of forks', () => {
      mountComponent();

      expect(findForksCountButton().text()).toBe('10');
    });

    it('is disabled when the user cannot read code', () => {
      mountComponent({ injections: { canReadCode: false } });

      expect(findForksCountButton().props('disabled')).toBe(true);
    });

    it('is enabled when the user can read code and has the correct link', () => {
      mountComponent();

      expect(findForksCountButton().props('disabled')).toBe(false);
      expect(findForksCountButton().attributes('href')).toBe('/project/forks');
    });
  });

  describe('fork button', () => {
    const userForkUrlPath = '/user/fork';
    const newForkPath = '/new/fork';

    const goToYourForkTitle = 'Go to your fork';
    const createNewForkTitle = 'Create new fork';
    const noPermissionsTitle = "You don't have permission to fork this project";

    it.each`
      userForkUrl        | canReadCode | canForkProject | isDisabled | title                 | href
      ${userForkUrlPath} | ${true}     | ${true}        | ${false}   | ${goToYourForkTitle}  | ${userForkUrlPath}
      ${userForkUrlPath} | ${false}    | ${true}        | ${true}    | ${createNewForkTitle} | ${userForkUrlPath}
      ${null}            | ${true}     | ${true}        | ${false}   | ${createNewForkTitle} | ${newForkPath}
      ${null}            | ${false}    | ${true}        | ${true}    | ${createNewForkTitle} | ${newForkPath}
      ${null}            | ${true}     | ${false}       | ${true}    | ${noPermissionsTitle} | ${newForkPath}
    `(
      'has the right enabled state, title, and link',
      ({ userForkUrl, canReadCode, canForkProject, isDisabled, title, href }) => {
        mountComponent({ injections: { userForkUrl, canReadCode, canForkProject } });

        expect(findForkButton().props('disabled')).toBe(isDisabled);
        expect(findForkButton().attributes('title')).toBe(title);
        expect(findForkButton().attributes('href')).toBe(href);
      },
    );
  });
});
