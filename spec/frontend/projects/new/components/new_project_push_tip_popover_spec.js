import { GlPopover, GlFormInputGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import NewProjectPushTipPopover from '~/projects/new/components/new_project_push_tip_popover.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('New project push tip popover', () => {
  let wrapper;
  const targetId = 'target';
  const pushToCreateProjectCommand = 'command';
  const projectHelpPath = 'path';

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findFormInput = () => wrapper.findComponent(GlFormInputGroup);
  const findHelpLink = () => wrapper.find('a');
  const findTarget = () => document.getElementById(targetId);

  const buildWrapper = ({ stubs = {} } = {}) => {
    wrapper = shallowMount(NewProjectPushTipPopover, {
      propsData: {
        target: findTarget(),
      },
      stubs: {
        GlFormInputGroup,
        ...stubs,
      },
      provide: {
        pushToCreateProjectCommand,
        projectHelpPath,
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture(`<a id="${targetId}"></a>`);
    buildWrapper();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders popover that targets the specified target', () => {
    // jest29 bug with recursive objects in toMatchObject https://github.com/jestjs/jest/issues/14734
    expect(findPopover().props('target')).toEqual(findTarget());

    expect(findPopover().props()).toMatchObject({
      triggers: 'click blur',
      placement: 'top',
      title: 'Push to create a project',
    });
  });

  it('renders a readonly form input with the push to create command', () => {
    buildWrapper({ stubs: { GlFormInputGroup: true } });

    expect(findFormInput().props()).toMatchObject({
      value: pushToCreateProjectCommand,
      selectOnClick: true,
    });
    expect(findFormInput().attributes()).toMatchObject({
      'aria-label': 'Push project from command line',
      readonly: '',
    });
  });

  it('allows copying the push command using the clipboard button', () => {
    expect(findClipboardButton().props()).toMatchObject({
      text: pushToCreateProjectCommand,
      tooltipPlacement: 'right',
      title: 'Copy command',
    });
  });

  it('displays a link to open the push command help page reference', () => {
    expect(findHelpLink().attributes().href).toBe(
      `${projectHelpPath}#create-a-new-project-with-git-push`,
    );
  });
});
