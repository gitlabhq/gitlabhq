import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import BlobHeader from '~/search/results/components/blob_header.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { EVENT_CLICK_CLIPBOARD_BUTTON, EVENT_CLICK_HEADER_LINK } from '~/search/results/tracking';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('BlobHeader', () => {
  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  let wrapper;

  const createComponent = (props, { query } = { query: MOCK_QUERY }) => {
    const store = new Vuex.Store({
      state: {
        query,
      },
    });

    wrapper = shallowMountExtended(BlobHeader, {
      propsData: {
        ...props,
      },
      store,
    });
  };

  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findHeaderLink = () => wrapper.findComponent(GlLink);
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const findProjectPath = () => wrapper.findByTestId('project-path-content');
  const findProjectName = () => wrapper.findByTestId('file-name-content');

  describe('component basics', () => {
    beforeEach(() => {
      createComponent({
        filePath: 'test/file.js',
        projectPath: 'Testjs/Test',
        fileUrl: 'https://gitlab.com/test/file.js',
        systemColorScheme: 'gl-light',
      });
    });

    it(`renders all parts of header`, () => {
      expect(findClipboardButton().exists()).toBe(true);
      expect(findFileIcon().exists()).toBe(true);
      expect(findProjectPath().props('href')).toBe('Testjs/Test');
      expect(findProjectName().exists()).toBe(true);
    });
  });

  describe('when there is project filter selected', () => {
    beforeEach(() => {
      createComponent(
        {
          filePath: 'test/file.js',
          projectPath: 'Testjs/Test',
          fileUrl: 'https://gitlab.com/test/file.js',
          systemColorScheme: 'gl-light',
        },
        { query: { ...MOCK_QUERY, project_id: 33 } },
      );
    });

    it(`renders without projectPath`, () => {
      expect(findClipboardButton().exists()).toBe(true);
      expect(findFileIcon().exists()).toBe(true);
      expect(findProjectPath().exists()).toBe(false);
      expect(findProjectName().exists()).toBe(true);
    });
  });

  describe('when there is no project path', () => {
    beforeEach(() => {
      createComponent({
        filePath: 'test/file.js',
        fileUrl: 'https://gitlab.com/test/file.js',
        systemColorScheme: 'gl-light',
      });
    });

    it(`renders withough projectPath`, () => {
      expect(findClipboardButton().exists()).toBe(true);
      expect(findFileIcon().exists()).toBe(true);
      expect(findProjectPath().exists()).toBe(false);
      expect(findProjectName().exists()).toBe(true);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent({
        filePath: 'test/file.js',
        projectPath: 'Testjs/Test',
        fileUrl: 'https://gitlab.com/test/file.js',
        systemColorScheme: 'gl-light',
      });
    });

    it.each`
      trackedLink            | event
      ${findHeaderLink}      | ${EVENT_CLICK_HEADER_LINK}
      ${findClipboardButton} | ${EVENT_CLICK_CLIPBOARD_BUTTON}
    `('emits $event on click', ({ trackedLink, event }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      trackedLink().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(event, {}, undefined);
    });
  });

  describe('path sanitization', () => {
    const maliciousFilePaths = [
      '<a href=#>malicious.js</a>',
      '<a href=# onclick="alert(1)">file.js</a>',
      "<a href=#><div class=js-new-user-signups-cap-reached data-dismiss-endpoint='/api/v4/user/emails?email=attacker123@test.se' data-defer-links=false data-feature-id=1><button class='js-close fixed-top gl-h-full gl-w-full'>Cloud Flare check you are human</button></div></a>",
      '\\u003cdiv\\u003emalicious.js\\u003c/div\\u003e',
      "\u003cdiv class=js-new-user-signups-cap-reached data-dismiss-endpoint='/api/v4/user/emails?email=attacker123@test.se' data-defer-links=false data-feature-id=1\u003e\u003cbutton class='js-close fixed-top gl-h-full gl-w-full'\u003eCloud Flare check you are human\u003c/button\u003e\u003c/div\u003e",
    ];

    it.each(maliciousFilePaths)('sanitizes malicious file path: %s', (filePath) => {
      createComponent({
        filePath,
        projectPath: 'Testjs/Test',
        fileUrl: 'https://gitlab.com/test/file.js',
        systemColorScheme: 'gl-light',
      });

      const fileNameContent = findProjectName();
      expect(fileNameContent.exists()).toBe(true);
      expect(fileNameContent.text()).not.toContain('<script>');
      expect(fileNameContent.text()).not.toContain('onclick');
      expect(fileNameContent.text()).not.toContain('<button>');
      expect(fileNameContent.text()).not.toContain('data-');
    });

    it('passes sanitized path to clipboard button', () => {
      const maliciousPath = '<script>alert("XSS")</b>innocent.js';

      createComponent({
        filePath: maliciousPath,
        projectPath: 'Testjs/Test',
        fileUrl: 'https://gitlab.com/test/file.js',
        systemColorScheme: 'gl-light',
      });

      expect(findClipboardButton().props('text')).toBe(maliciousPath);
      expect(findClipboardButton().props('gfm')).not.toContain('<script>');
    });
  });

  describe('highlighting with search query', () => {
    it('applies highlighting when search term is in file path', () => {
      const filePath = 'folder/searchTerm/file.js';

      createComponent(
        {
          filePath,
          projectPath: 'Testjs/Test',
          fileUrl: 'https://gitlab.com/test/file.js',
          systemColorScheme: 'gl-light',
        },
        { query: { search: 'searchTerm' } },
      );
      const fileNameContent = findProjectName().html();
      expect(fileNameContent).toContain('<span class="highlight-search-term');
      expect(fileNameContent).toContain('searchTerm');
    });

    it('does not apply highlighting for potential regex patterns', () => {
      const filePath = 'folder/test+/file.js';

      window.containsPotentialRegex = jest.fn().mockReturnValue(true);

      createComponent(
        {
          filePath,
          projectPath: 'Testjs/Test',
          fileUrl: 'https://gitlab.com/test/file.js',
          systemColorScheme: 'gl-light',
        },
        { query: { search: 'test+' } },
      );

      const fileNameContent = findProjectName().html();
      expect(fileNameContent).not.toContain('<span class="highlight-search-term');
    });

    it('handles empty search query gracefully', () => {
      const filePath = 'folder/test/file.js';

      createComponent(
        {
          filePath,
          projectPath: 'Testjs/Test',
          fileUrl: 'https://gitlab.com/test/file.js',
          systemColorScheme: 'gl-light',
        },
        { query: { search: '' } },
      );

      const fileNameContent = findProjectName();

      expect(fileNameContent.html()).not.toContain('<span class="highlight-search-term');
      expect(fileNameContent.text()).toContain(filePath);
    });
  });
});
