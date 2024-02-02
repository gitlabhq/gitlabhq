import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import StarCount from '~/stars/components/star_count.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setStarStatus from '~/stars/components/graphql/mutations/star.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('StarCount', () => {
  let wrapper;
  let mockApollo;

  const $toast = {
    show: jest.fn(),
  };

  const findStarButton = () => wrapper.findByTestId('star-button');
  const findStarCount = () => wrapper.findByTestId('star-count');

  const initialStarCount = 17;
  const setStarStatusResponse = {
    data: {
      starProject: {
        count: initialStarCount + 1,
      },
    },
  };
  const setUnstarStatusResponse = {
    data: {
      starProject: {
        count: initialStarCount - 1,
      },
    },
  };

  const createComponent = ({
    setStarStatusHandler = jest.fn().mockResolvedValue(setStarStatusResponse),
    injections = {},
    isLoggedIn = true,
  } = {}) => {
    if (isLoggedIn) {
      window.gon.current_user_id = 1;
    }

    mockApollo = createMockApollo([[setStarStatus, setStarStatusHandler]]);

    wrapper = mountExtended(StarCount, {
      apolloProvider: mockApollo,
      provide: {
        projectId: 1,
        projectPath: '/project/stars',
        starCount: initialStarCount,
        starred: false,
        starrersPath: '/project/stars/-/starrers',
        signInPath: 'sign/in/path',
        ...injections,
      },
      mocks: {
        $toast,
      },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('star count', () => {
    it('renders the correct number of stars', () => {
      createComponent();

      expect(findStarCount().text()).toEqual(`${initialStarCount}`);
    });

    it('renders the correct starrers link', () => {
      createComponent();

      expect(findStarCount().attributes('href')).toBe('/project/stars/-/starrers');
    });
  });

  describe('star button', () => {
    const starText = 'Star';
    const unstarText = 'Unstar';

    it.each`
      starred  | text
      ${true}  | ${unstarText}
      ${false} | ${starText}
    `('has the right text', ({ starred, text }) => {
      createComponent({ injections: { starred } });

      expect(findStarButton().text()).toBe(text);
    });
  });

  describe('updates information when clicking star button', () => {
    const starText = 'Star';
    const unstarText = 'Unstar';

    it.each`
      starred  | initialCount | initialText   | updatedCount | updatedText   | response
      ${false} | ${'17'}      | ${starText}   | ${'18'}      | ${unstarText} | ${setStarStatusResponse}
      ${true}  | ${'17'}      | ${unstarText} | ${'16'}      | ${starText}   | ${setUnstarStatusResponse}
    `(
      'sets the correct count and text',
      async ({ starred, initialCount, initialText, updatedCount, updatedText, response }) => {
        createComponent({
          injections: { starred },
          setStarStatusHandler: jest.fn().mockResolvedValue(response),
        });

        expect(findStarCount().text()).toBe(initialCount);
        expect(findStarButton().text()).toBe(initialText);

        findStarButton().vm.$emit('click');

        await waitForPromises();

        expect(findStarCount().text()).toBe(updatedCount);
        expect(findStarButton().text()).toBe(updatedText);
      },
    );
  });

  describe('toast', () => {
    it('displays a toast error message', async () => {
      createComponent({
        setStarStatusHandler: jest.fn().mockRejectedValue('Internal server error'),
      });

      expect(findStarCount().text()).toBe(`${initialStarCount}`);
      expect(findStarButton().text()).toBe('Star');

      findStarButton().vm.$emit('click');

      await waitForPromises();

      expect($toast.show).toHaveBeenCalled();
      expect(findStarCount().text()).toBe(`${initialStarCount}`);
      expect(findStarButton().text()).toBe('Star');
    });
  });

  describe('non-logged in user', () => {
    it('redirects to the sign-in page', () => {
      createComponent({ isLoggedIn: false });

      expect(findStarButton().attributes('href')).toBe('sign/in/path');
    });
  });
});
