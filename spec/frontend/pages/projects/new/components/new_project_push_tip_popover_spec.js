import { GlPopover, GlFormInputGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NewProjectPushTipPopover from '~/pages/projects/new/components/new_project_push_tip_popover.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('New project push tip popover', () => {
  let wrapper;
  const targetId = 'target';
  const pushToCreateProjectCommand = 'command';
  const workingWithProjectsHelpPath = 'path';

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findFormInput = () => wrapper.findComponent(GlFormInputGroup);
  const findHelpLink = () => wrapper.find('a');
  const findTarget = () => document.getElementById(targetId);

  const buildWrapper = () => {
    wrapper = shallowMount(NewProjectPushTipPopover, {
      propsData: {
        target: findTarget(),
      },
      stubs: {
        GlFormInputGroup,
      },
      provide: {
        pushToCreateProjectCommand,
        workingWithProjectsHelpPath,
      },
    });
  };

  beforeEach(() => {
    setFixtures(`<a id="${targetId}"></a>`);
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders popover that targets the specified target', () => {
    expect(findPopover().props()).toMatchObject({
      target: findTarget(),
      triggers: 'click blur',
      placement: 'top',
      title: 'Push to create a project',
    });
  });

  it('renders a readonly form input with the push to create command', () => {
    expect(findFormInput().props()).toMatchObject({
      value: pushToCreateProjectCommand,
      selectOnClick: true,
    });
    expect(findFormInput().attributes()).toMatchObject({
      'aria-label': 'Push project from command line',
      readonly: 'readonly',
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
      `${workingWithProjectsHelpPath}#push-to-create-a-new-project`,
    );
  });
});
