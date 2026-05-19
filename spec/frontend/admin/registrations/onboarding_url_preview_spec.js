import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { initOnboardingUrlPreview } from '~/admin/registrations/onboarding_url_preview';

describe('initOnboardingUrlPreview', () => {
  const ROOT_URL = 'https://gitlab.example.com/';

  let groupInput;
  let projectInput;
  let groupHidden;
  let projectHidden;
  let groupPathSpan;
  let projectPathSpan;
  let rootUrlSpan;

  beforeEach(() => {
    setHTMLFixture(`
      <div data-onboarding-root-url="${ROOT_URL}">
        <span class="js-onboarding-root-url"></span>
        <span data-testid="url-group-path"></span>
        <span data-testid="url-project-path"></span>
      </div>
      <input id="js-onboarding-group-name" type="text" value="" />
      <input id="js-onboarding-project-name" type="text" value="" />
      <input id="js-onboarding-group-path" type="hidden" value="" />
      <input id="js-onboarding-project-path" type="hidden" value="" />
      <select id="project_project_template_name">
        <option value="">Blank project (default)</option>
        <option value="rails">Ruby on Rails</option>
      </select>
    `);

    groupInput = document.getElementById('js-onboarding-group-name');
    projectInput = document.getElementById('js-onboarding-project-name');
    groupHidden = document.getElementById('js-onboarding-group-path');
    projectHidden = document.getElementById('js-onboarding-project-path');
    groupPathSpan = document.querySelector('[data-testid="url-group-path"]');
    projectPathSpan = document.querySelector('[data-testid="url-project-path"]');
    rootUrlSpan = document.querySelector('.js-onboarding-root-url');

    initOnboardingUrlPreview();
  });

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  afterEach(() => {
    resetHTMLFixture();
  });

  it('sets the root URL on init', () => {
    expect(rootUrlSpan.textContent).toBe(ROOT_URL);
  });

  describe('with empty inputs', () => {
    it('shows placeholder group path in the URL preview', () => {
      expect(groupPathSpan.textContent).toBe('my-group');
    });

    it('shows placeholder project path in the URL preview', () => {
      expect(projectPathSpan.textContent).toBe('my-project');
    });

    it('keeps hidden group path field empty', () => {
      expect(groupHidden.value).toBe('');
    });

    it('keeps hidden project path field empty', () => {
      expect(projectHidden.value).toBe('');
    });
  });

  describe('when group name is entered', () => {
    beforeEach(() => {
      groupInput.value = 'My Awesome Group';
      groupInput.dispatchEvent(new Event('input'));
    });

    it('slugifies the name into the URL preview', () => {
      expect(groupPathSpan.textContent).toBe('my-awesome-group');
    });

    it('sets the hidden group path field', () => {
      expect(groupHidden.value).toBe('my-awesome-group');
    });
  });

  describe('when project name is entered', () => {
    beforeEach(() => {
      projectInput.value = 'My Cool Project';
      projectInput.dispatchEvent(new Event('input'));
    });

    it('slugifies the name into the URL preview', () => {
      expect(projectPathSpan.textContent).toBe('my-cool-project');
    });

    it('sets the hidden project path field', () => {
      expect(projectHidden.value).toBe('my-cool-project');
    });
  });

  describe('when group input is cleared after being set', () => {
    it('clears the hidden group path field', () => {
      groupInput.value = 'Some Group';
      groupInput.dispatchEvent(new Event('input'));
      expect(groupHidden.value).toBe('some-group');

      groupInput.value = '';
      groupInput.dispatchEvent(new Event('input'));
      expect(groupHidden.value).toBe('');
    });

    it('shows the placeholder in the URL preview', () => {
      groupInput.value = 'Some Group';
      groupInput.dispatchEvent(new Event('input'));

      groupInput.value = '';
      groupInput.dispatchEvent(new Event('input'));
      expect(groupPathSpan.textContent).toBe('my-group');
    });
  });

  describe('when project input is cleared after being set', () => {
    it('clears the hidden project path field', () => {
      projectInput.value = 'Some Project';
      projectInput.dispatchEvent(new Event('input'));
      expect(projectHidden.value).toBe('some-project');

      projectInput.value = '';
      projectInput.dispatchEvent(new Event('input'));
      expect(projectHidden.value).toBe('');
    });
  });

  describe('when a project template is selected', () => {
    let templateSelect;

    beforeEach(() => {
      templateSelect = document.getElementById('project_project_template_name');
    });

    it('tracks the select_project_template event when a template is chosen', () => {
      const { trackEventSpy } = bindInternalEventDocument(document.body);

      templateSelect.value = 'rails';
      templateSelect.dispatchEvent(new Event('change'));

      expect(trackEventSpy).toHaveBeenCalledWith('select_project_template', { label: 'rails' });
    });

    it('does not track when blank project is selected', () => {
      const { trackEventSpy } = bindInternalEventDocument(document.body);

      templateSelect.value = '';
      templateSelect.dispatchEvent(new Event('change'));

      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });

  describe('when required elements are missing', () => {
    it('does not throw when group input is absent', () => {
      resetHTMLFixture();
      setHTMLFixture('<div data-onboarding-root-url="https://example.com/"></div>');
      expect(() => initOnboardingUrlPreview()).not.toThrow();
    });
  });
});
