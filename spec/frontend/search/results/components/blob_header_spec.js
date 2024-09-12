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

  const createComponent = (props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
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
      expect(findProjectPath().exists()).toBe(true);
      expect(findProjectName().exists()).toBe(true);
    });
  });

  describe('limited component', () => {
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
});
