import { GlMultiStepFormTemplate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportFromFogbugzApp from '~/import/fogbugz/import_from_fogbugz_app.vue';

describe('Import from FugBugz app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ImportFromFogbugzApp, {
      propsData: {
        backButtonPath: '/projects/new#import_project',
        formPath: '/import/fogbugz/callback',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepForm = () => wrapper.findComponent(GlMultiStepFormTemplate);
  const findBackButton = () => wrapper.findByTestId('back-button');
  const findNextButton = () => wrapper.findByTestId('next-button');

  it('renders a form', () => {
    expect(findMultiStepForm().exists()).toBe(true);
  });

  describe('back button', () => {
    it('renders a back button', () => {
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().attributes('href')).toBe('/projects/new#import_project');
    });
  });

  describe('next button', () => {
    it('renders a next button', () => {
      expect(findNextButton().exists()).toBe(true);
      expect(findNextButton().attributes('type')).toBe('submit');
    });
  });
});
