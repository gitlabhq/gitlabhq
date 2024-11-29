import { GlFormGroup, GlFormSelect, GlLink, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mockTracking } from 'helpers/tracking_helper';
import DeploymentTargetSelect from '~/projects/new/components/deployment_target_select.vue';
import {
  DEPLOYMENT_TARGET_SELECTIONS,
  DEPLOYMENT_TARGET_LABEL,
  DEPLOYMENT_TARGET_EVENT,
  VISIT_DOCS_EVENT,
  NEW_PROJECT_FORM,
  K8S_OPTION,
} from '~/projects/new/constants';

describe('Deployment target select', () => {
  let wrapper;
  let trackingSpy;

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findSelect = () => wrapper.findComponent(GlFormSelect);
  const findText = () => wrapper.findComponent(GlSprintf);
  const findLink = () => wrapper.findComponent(GlLink);

  const createdWrapper = () => {
    wrapper = shallowMount(DeploymentTargetSelect, {
      stubs: {
        GlFormGroup,
        GlFormSelect,
        GlSprintf,
      },
    });
  };

  const createForm = () => {
    setHTMLFixture(`
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
    resetHTMLFixture();
  });

  it('renders the correct label', () => {
    expect(findFormGroup().attributes('label')).toBe('Project deployment target (optional)');
  });

  it('renders a select with the disabled default option', () => {
    expect(findSelect().find('option').text()).toBe('Select the deployment target');
    expect(findSelect().find('option').attributes('disabled')).toBeDefined();
  });

  describe.each`
    selectedTarget                           | formSubmitted | eventSent
    ${null}                                  | ${true}       | ${false}
    ${DEPLOYMENT_TARGET_SELECTIONS[0].value} | ${false}      | ${false}
    ${DEPLOYMENT_TARGET_SELECTIONS[0].value} | ${true}       | ${true}
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

  describe.each`
    selectedTarget                           | isTextShown
    ${null}                                  | ${false}
    ${DEPLOYMENT_TARGET_SELECTIONS[0].value} | ${true}
    ${DEPLOYMENT_TARGET_SELECTIONS[1].value} | ${false}
  `('K8s education text', ({ selectedTarget, isTextShown }) => {
    beforeEach(() => {
      findSelect().vm.$emit('input', selectedTarget);
    });

    it(`is ${!isTextShown ? 'not ' : ''}shown when selected option is ${selectedTarget}`, () => {
      expect(findText().exists()).toBe(isTextShown);
    });
  });

  describe('when user clicks on the docs link', () => {
    beforeEach(async () => {
      findSelect().vm.$emit('input', K8S_OPTION.value);
      await nextTick();

      findLink().trigger('click');
    });

    it('sends the snowplow tracking event', () => {
      expect(trackingSpy).toHaveBeenCalledWith('_category_', VISIT_DOCS_EVENT, {
        label: DEPLOYMENT_TARGET_LABEL,
      });
    });
  });
});
