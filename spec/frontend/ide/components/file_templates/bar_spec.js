import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import Bar from '~/ide/components/file_templates/bar.vue';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

describe('IDE file templates bar component', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    store.state.openFiles.push({
      ...file('file'),
      opened: true,
      active: true,
    });

    wrapper = mount(Bar, { store });
  });

  describe('template type dropdown', () => {
    it('renders dropdown component', () => {
      expect(wrapper.find('.dropdown').text()).toContain('Choose a type');
    });

    it('calls setSelectedTemplateType when clicking item', async () => {
      await wrapper.find('.dropdown-menu button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('fileTemplates/setSelectedTemplateType', {
        name: '.gitlab-ci.yml',
        key: 'gitlab_ci_ymls',
      });
    });
  });

  describe('template dropdown', () => {
    beforeEach(() => {
      store.state.fileTemplates.templates = [
        {
          name: 'test',
        },
      ];
      store.state.fileTemplates.selectedTemplateType = {
        name: '.gitlab-ci.yml',
        key: 'gitlab_ci_ymls',
      };
    });

    it('renders dropdown component', () => {
      expect(wrapper.findAll('.dropdown').at(1).text()).toContain('Choose a template');
    });

    it('calls fetchTemplate on dropdown open', async () => {
      await wrapper.findAll('.dropdown-menu').at(1).find('button').trigger('click');

      expect(store.dispatch).toHaveBeenCalledWith('fileTemplates/fetchTemplate', {
        name: 'test',
      });
    });
  });

  const findUndoButton = () => wrapper.find('.btn-default-secondary');
  it('shows undo button if updateSuccess is true', async () => {
    store.state.fileTemplates.updateSuccess = true;
    await nextTick();

    expect(findUndoButton().isVisible()).toBe(true);
  });

  it('calls undoFileTemplate when clicking undo button', async () => {
    await findUndoButton().trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('fileTemplates/undoFileTemplate', undefined);
  });

  it('calls setSelectedTemplateType if activeFile name matches a template', async () => {
    const fileName = '.gitlab-ci.yml';
    store.state.openFiles = [{ ...file(fileName), opened: true, active: true }];

    await nextTick();

    expect(store.dispatch).toHaveBeenCalledWith('fileTemplates/setSelectedTemplateType', {
      name: fileName,
      key: 'gitlab_ci_ymls',
    });
  });
});
