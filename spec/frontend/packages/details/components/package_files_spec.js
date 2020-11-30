import { mount } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import component from '~/packages/details/components/package_files.vue';

import { npmFiles, mavenFiles } from '../../mock_data';

describe('Package Files', () => {
  let wrapper;

  const findAllRows = () => wrapper.findAll('[data-testid="file-row"');
  const findFirstRow = () => findAllRows().at(0);
  const findFirstRowDownloadLink = () => findFirstRow().find('[data-testid="download-link"');
  const findFirstRowFileIcon = () => findFirstRow().find(FileIcon);
  const findFirstRowCreatedAt = () => findFirstRow().find(TimeAgoTooltip);

  const createComponent = (packageFiles = npmFiles) => {
    wrapper = mount(component, {
      propsData: {
        packageFiles,
      },
      stubs: {
        ...stubChildren(component),
        GlTable: false,
        GlLink: '<div><slot></slot></div>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('rows', () => {
    it('renders a single file for an npm package', () => {
      createComponent();

      expect(findAllRows()).toHaveLength(1);
    });

    it('renders multiple files for a package that contains more than one file', () => {
      createComponent(mavenFiles);

      expect(findAllRows()).toHaveLength(2);
    });
  });

  describe('link', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowDownloadLink().exists()).toBe(true);
    });

    it('has the correct attrs bound', () => {
      createComponent();

      expect(findFirstRowDownloadLink().attributes('href')).toBe(npmFiles[0].download_path);
    });

    it('emits "download-file" event on click', () => {
      createComponent();

      findFirstRowDownloadLink().vm.$emit('click');

      expect(wrapper.emitted('download-file')).toEqual([[]]);
    });
  });

  describe('file-icon', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowFileIcon().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      createComponent();

      expect(findFirstRowFileIcon().props('fileName')).toBe(npmFiles[0].file_name);
    });
  });

  describe('time-ago tooltip', () => {
    it('exists', () => {
      createComponent();

      expect(findFirstRowCreatedAt().exists()).toBe(true);
    });

    it('has the correct props bound', () => {
      createComponent();

      expect(findFirstRowCreatedAt().props('time')).toBe(npmFiles[0].created_at);
    });
  });
});
