import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking } from 'helpers/tracking_helper';
import DeploymentTargetSelect from '~/projects/new/components/deployment_target_select.vue';
import {
  DEPLOYMENT_TARGET_SELECTIONS,
  DEPLOYMENT_TARGET_LABEL,
  DEPLOYMENT_TARGET_EVENT,
  NEW_PROJECT_FORM,
} from '~/projects/new/constants';

describe('Deployment target select', () => {
  let wrapper;
  let trackingSpy;

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findSelect = () => wrapper.findComponent(GlFormSelect);

  const createdWrapper = () => {
    wrapper = shallowMount(DeploymentTargetSelect, {
      stubs: {
        GlFormSelect,
      },
    });
  };

  const createForm = () => {
    setFixtures(`
      <form id="${NEW_PROJECT_FORM}">
      </form>
    `);
  };

  beforeEach(() => {
    createForm();
    createdWrapper();

    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the correct label', () => {
    expect(findFormGroup().attributes('label')).toBe('Project deployment target (optional)');
  });

  it('renders a select with the disabled default option', () => {
    expect(findSelect().find('option').text()).toBe('Select the deployment target');
    expect(findSelect().find('option').attributes('disabled')).toBe('disabled');
  });

  describe.each`
    selectedTarget                     | formSubmitted | eventSent
    ${null}                            | ${true}       | ${false}
    ${DEPLOYMENT_TARGET_SELECTIONS[0]} | ${false}      | ${false}
    ${DEPLOYMENT_TARGET_SELECTIONS[0]} | ${true}       | ${true}
  `('Snowplow tracking event', ({ selectedTarget, formSubmitted, eventSent }) => {
    beforeEach(() => {
      findSelect().vm.$emit('input', selectedTarget);

      if (formSubmitted) {
        const form = document.getElementById(NEW_PROJECT_FORM);
        form.dispatchEvent(new Event('submit'));
      }
    });

    if (eventSent) {
      it(`is sent, when the the selectedTarget is ${selectedTarget} and the formSubmitted is ${formSubmitted} `, () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, DEPLOYMENT_TARGET_EVENT, {
          label: DEPLOYMENT_TARGET_LABEL,
          property: selectedTarget,
        });
      });
    } else {
      it(`is not sent, when the the selectedTarget is ${selectedTarget} and the formSubmitted is ${formSubmitted} `, () => {
        expect(trackingSpy).toHaveBeenCalledTimes(0);
      });
    }
  });
});
