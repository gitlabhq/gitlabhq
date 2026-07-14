import VueApollo from 'vue-apollo';
import Vue from 'vue';

import organizationUpdateResponse from 'test_fixtures/graphql/organizations/organization_update.mutation.graphql.json';
import organizationUpdateResponseWithErrors from 'test_fixtures/graphql/organizations/organization_update.mutation.graphql_with_errors.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import VisibilityLevel from '~/organizations/settings/general/components/visibility_level.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import organizationUpdateMutation from '~/organizations/settings/general/graphql/mutations/organization_update.mutation.graphql';
import { createAlert } from '~/alert';
import { scrollUp } from '~/lib/utils/scroll_utils';
import {
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
} from '~/visibility_level/constants';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/scroll_utils', () => ({
  scrollUp: jest.fn(),
}));

describe('VisibilityLevel', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
      path: 'foo-bar',
      description: 'foo bar',
      visibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    },
    maxGroupVisibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER,
  };

  const defaultPropsData = {
    id: 'organization-settings-visibility',
    expanded: false,
  };

  const successHandler = jest.fn().mockResolvedValue(organizationUpdateResponse);

  const createComponent = ({
    handlers = [[organizationUpdateMutation, successHandler]],
    provide = {},
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = mountExtended(VisibilityLevel, {
      attachTo: document.body,
      apolloProvider: mockApollo,
      provide: { ...defaultProvide, ...provide },
      propsData: defaultPropsData,
      stubs: {
        SettingsBlock,
      },
    });
  };

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findVisibilityLevelRadioButtons = () => wrapper.findComponent(VisibilityLevelRadioButtons);
  const findFormErrorsAlert = () => wrapper.findComponent(FormErrorsAlert);
  const findSubmitButton = () => wrapper.findByTestId('submit-button');
  const submitForm = async () => {
    await findSubmitButton().trigger('click');
    await waitForPromises();
  };

  afterEach(() => {
    mockApollo = null;
  });

  it('renders settings block with correct props and description', () => {
    createComponent();

    expect(findSettingsBlock().props()).toEqual({ title: 'Visibility', ...defaultPropsData });
    expect(findSettingsBlock().text()).toContain('Choose organization visibility level.');
  });

  describe('when SettingsBlock component emits `toggle-expand` event', () => {
    beforeEach(() => {
      createComponent();
      findSettingsBlock().vm.$emit('toggle-expand', true);
    });

    it('emits `toggle-expand` event', () => {
      expect(wrapper.emitted('toggle-expand')).toEqual([[true]]);
    });
  });

  it('renders visibility level field with private and public options', () => {
    createComponent();

    expect(findVisibilityLevelRadioButtons().props()).toEqual({
      checked: VISIBILITY_LEVEL_PRIVATE_INTEGER,
      visibilityLevels: [VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER],
      visibilityLevelDescriptions: ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
      minVisibilityLevel: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    });
  });

  describe('when `maxGroupVisibilityLevel` restricts the available visibility levels', () => {
    beforeEach(() => {
      createComponent({ provide: { maxGroupVisibilityLevel: VISIBILITY_LEVEL_PUBLIC_INTEGER } });
    });

    it('passes `maxGroupVisibilityLevel` to radio buttons as `minVisibilityLevel`', () => {
      expect(findVisibilityLevelRadioButtons().props('minVisibilityLevel')).toBe(
        VISIBILITY_LEVEL_PUBLIC_INTEGER,
      );
    });

    it('renders disabled message', () => {
      expect(
        wrapper
          .findByText(
            'Visibility levels that are more restrictive than the groups in this Organization have been disabled.',
          )
          .exists(),
      ).toBe(true);
    });
  });

  describe('when form is submitting', () => {
    beforeEach(async () => {
      createComponent({
        handlers: [
          [organizationUpdateMutation, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
        ],
      });

      await findSubmitButton().trigger('click');
    });

    it('sets submit button `loading` prop to `true`', () => {
      expect(findSubmitButton().props('loading')).toBe(true);
    });
  });

  describe('when form is submitted successfully', () => {
    beforeEach(async () => {
      createComponent();
      findVisibilityLevelRadioButtons().vm.$emit('input', VISIBILITY_LEVEL_PUBLIC_INTEGER);

      await submitForm();
    });

    it('calls mutation with the selected visibility', () => {
      expect(successHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/Organizations::Organization/1',
          visibility: 'public',
        },
      });
    });

    it('displays info alert and scrolls up', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Organization visibility successfully updated.',
        variant: 'info',
      });
      expect(scrollUp).toHaveBeenCalled();
    });
  });

  describe('when form submission returns GraphQL errors', () => {
    beforeEach(async () => {
      createComponent({
        handlers: [
          [
            organizationUpdateMutation,
            jest.fn().mockResolvedValue(organizationUpdateResponseWithErrors),
          ],
        ],
      });

      await submitForm();
    });

    it('displays form errors alert', () => {
      expect(findFormErrorsAlert().props()).toStrictEqual({
        errors: organizationUpdateResponseWithErrors.data.organizationUpdate.errors,
        scrollOnError: true,
      });
    });

    it('does not display info alert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('when form submission fails', () => {
    const error = new Error();

    beforeEach(async () => {
      createComponent({
        handlers: [[organizationUpdateMutation, jest.fn().mockRejectedValue(error)]],
      });

      await submitForm();
    });

    it('displays error alert and scrolls up', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred updating your organization. Please try again.',
        error,
        captureError: true,
      });
      expect(scrollUp).toHaveBeenCalled();
    });
  });
});
