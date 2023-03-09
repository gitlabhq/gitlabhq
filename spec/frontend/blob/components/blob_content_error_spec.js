import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobContentError from '~/blob/components/blob_content_error.vue';

import { BLOB_RENDER_ERRORS } from '~/blob/components/constants';

describe('Blob Content Error component', () => {
  let wrapper;

  function createComponent(props = {}) {
    wrapper = shallowMount(BlobContentError, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  }

  describe('collapsed and too large blobs', () => {
    it.each`
      error                                   | reason                           | options
      ${BLOB_RENDER_ERRORS.REASONS.COLLAPSED} | ${'it is larger than 1.00 MiB'}  | ${[BLOB_RENDER_ERRORS.OPTIONS.LOAD.text, BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD.text]}
      ${BLOB_RENDER_ERRORS.REASONS.TOO_LARGE} | ${'it is larger than 10.00 MiB'} | ${[BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD.text]}
    `('renders correct reason for $error.id', ({ error, reason, options }) => {
      createComponent({
        viewerError: error.id,
      });
      expect(wrapper.text()).toContain(reason);
      options.forEach((option) => {
        expect(wrapper.text()).toContain(option);
      });
    });
  });

  describe('external blob', () => {
    it.each`
      storageType         | reason                                                     | options
      ${'lfs'}            | ${BLOB_RENDER_ERRORS.REASONS.EXTERNAL.text.lfs}            | ${[BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD.text]}
      ${'build_artifact'} | ${BLOB_RENDER_ERRORS.REASONS.EXTERNAL.text.build_artifact} | ${[BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD.text]}
      ${'default'}        | ${BLOB_RENDER_ERRORS.REASONS.EXTERNAL.text.default}        | ${[BLOB_RENDER_ERRORS.OPTIONS.DOWNLOAD.text]}
    `('renders correct reason for $storageType blob', ({ storageType, reason, options }) => {
      createComponent({
        viewerError: BLOB_RENDER_ERRORS.REASONS.EXTERNAL.id,
        blob: {
          externalStorage: storageType,
        },
      });
      expect(wrapper.text()).toContain(reason);
      options.forEach((option) => {
        expect(wrapper.text()).toContain(option);
      });
    });
  });
});
