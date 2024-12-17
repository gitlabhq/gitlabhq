import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import RunnerInstructionsModal from '~/ci/runner/components/registration/runner_instructions/runner_instructions_modal.vue';
import {
  I18N_GET_STARTED,
  I18N_RUNNERS_ARE_AGENTS,
  I18N_CREATE_RUNNER_LINK,
  I18N_STILL_USING_REGISTRATION_TOKENS,
  I18N_CONTACT_ADMIN_TO_REGISTER,
} from '~/ci/runner/constants';

import {
  mockRegistrationToken,
  newRunnerPath as mockNewRunnerPath,
} from 'jest/ci/runner/mock_data';

import RunnerListEmptyState from '~/ci/runner/components/runner_list_empty_state.vue';

describe('RunnerListEmptyState', () => {
  let wrapper;
  let glFeatures;

  const findEmptySearchResult = () => wrapper.findComponent(EmptyResult);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findLink = () => wrapper.findComponent(GlLink);
  const findRunnerInstructionsModal = () => wrapper.findComponent(RunnerInstructionsModal);

  const expectTitleToBe = (title) => {
    expect(findEmptyState().find('h1').text()).toBe(title);
  };
  const expectDescriptionToBe = (sentences) => {
    expect(findEmptyState().find('p').text()).toMatchInterpolatedText(sentences.join(' '));
  };

  const createComponent = ({ props, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerListEmptyState, {
      propsData: {
        ...props,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      stubs: {
        GlEmptyState,
        GlSprintf,
      },
      provide: { glFeatures },
    });
  };

  beforeEach(() => {
    glFeatures = null;
  });

  describe('when search is not filtered', () => {
    describe.each`
      newRunnerPath        | registrationToken        | expectedMessages
      ${mockNewRunnerPath} | ${mockRegistrationToken} | ${[I18N_CREATE_RUNNER_LINK, I18N_STILL_USING_REGISTRATION_TOKENS]}
      ${mockNewRunnerPath} | ${null}                  | ${[I18N_CREATE_RUNNER_LINK]}
      ${null}              | ${mockRegistrationToken} | ${[I18N_STILL_USING_REGISTRATION_TOKENS]}
      ${null}              | ${null}                  | ${[I18N_CONTACT_ADMIN_TO_REGISTER]}
    `(
      'when newRunnerPath is $newRunnerPath and registrationToken is $registrationToken',
      ({ newRunnerPath, registrationToken, expectedMessages }) => {
        beforeEach(() => {
          createComponent({
            props: {
              newRunnerPath,
              registrationToken,
            },
          });
        });

        it('shows title', () => {
          expectTitleToBe(I18N_GET_STARTED);
        });

        it('renders an illustration', () => {
          expect(findEmptyState().props('svgPath')).toBe(EMPTY_STATE_SVG_URL);
        });

        it(`shows description: "${expectedMessages.join(' ')}"`, () => {
          expectDescriptionToBe([I18N_RUNNERS_ARE_AGENTS, ...expectedMessages]);
        });
      },
    );

    describe('with newRunnerPath and registration token', () => {
      beforeEach(() => {
        createComponent({
          props: {
            registrationToken: mockRegistrationToken,
            newRunnerPath: mockNewRunnerPath,
          },
        });
      });

      it('shows links to the new runner page and registration instructions', () => {
        expect(findLinks().at(0).attributes('href')).toBe(mockNewRunnerPath);

        const { value } = getBinding(findLinks().at(1).element, 'gl-modal');
        expect(findRunnerInstructionsModal().props('modalId')).toEqual(value);
      });
    });

    describe('with newRunnerPath and no registration token', () => {
      beforeEach(() => {
        createComponent({
          props: {
            registrationToken: mockRegistrationToken,
            newRunnerPath: null,
          },
        });
      });

      it('opens a runner registration instructions modal with a link', () => {
        const { value } = getBinding(findLink().element, 'gl-modal');
        expect(findRunnerInstructionsModal().props('modalId')).toEqual(value);
      });
    });

    describe('with no newRunnerPath nor registration token', () => {
      beforeEach(() => {
        createComponent({
          props: {
            registrationToken: null,
            newRunnerPath: null,
          },
        });
      });

      it('has no link', () => {
        expect(findLink().exists()).toBe(false);
      });
    });
  });

  describe('when search is filtered', () => {
    beforeEach(() => {
      createComponent({ props: { isSearchFiltered: true } });
    });

    it('renders a EmptyResult component', () => {
      expect(findEmptySearchResult().exists()).toBe(true);
    });
  });
});
