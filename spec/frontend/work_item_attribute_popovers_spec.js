import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { handleIssuablePopoverMount } from 'ee_else_ce/issuable/popover';

import initWorkItemAttributePopovers from '~/work_item_attribute_popovers';

jest.mock('~/lib/graphql');
jest.mock('ee_else_ce/issuable/popover');

describe('Work Item Attribute Popovers', () => {
  const triggerEvent = (eventName, el, target) => {
    const event = new MouseEvent(eventName, {
      bubbles: true,
      cancelable: true,
      view: window,
    });

    Object.defineProperty(event, 'target', {
      value: target,
      enumerable: true,
    });

    el.dispatchEvent(event);
  };

  beforeEach(() => {
    setHTMLFixture(`
      <div class="attributes-wrapper">
        <div class="js-without-popover" data-reference-type="milestone" data-placement="left" data-milestone="1">17.0<div>
        <div class="has-popover js-with-popover" data-reference-type="milestone" data-placement="left" data-milestone="2">18.0<div>
      </div>
    `);
    initWorkItemAttributePopovers();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('calls handleIssuablePopoverMount to mount popover', () => {
    const mockTarget = document.querySelector('.js-with-popover');
    triggerEvent('mouseover', document, mockTarget);
    triggerEvent('mouseenter', mockTarget, mockTarget);

    expect(handleIssuablePopoverMount).toHaveBeenCalledWith({
      apolloProvider: expect.any(Object),
      referenceType: 'milestone',
      placement: 'left',
      milestone: '2',
      innerText: '18.0',
      target: mockTarget,
    });
  });

  it('does not call handleIssuablePopoverMount when target is missing required attributes for popover', () => {
    const mockTarget = document.querySelector('.js-without-popover');
    triggerEvent('mouseover', document, mockTarget);
    triggerEvent('mouseenter', mockTarget, mockTarget);

    expect(handleIssuablePopoverMount).not.toHaveBeenCalled();
  });
});
