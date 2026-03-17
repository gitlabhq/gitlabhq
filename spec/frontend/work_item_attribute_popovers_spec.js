import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { handleIssuablePopoverMount } from '~/issuable/popover';

import initWorkItemAttributePopovers from '~/work_item_attribute_popovers';

jest.mock('~/lib/graphql');
jest.mock('~/issuable/popover');

describe('Work Item Attribute Popovers', () => {
  const triggerMouseover = (el) => {
    el.dispatchEvent(
      new MouseEvent('mouseover', {
        bubbles: true,
        cancelable: true,
        view: window,
      }),
    );
  };

  beforeEach(() => {
    setHTMLFixture(`
      <div class="attributes-wrapper">
        <div class="js-without-popover" data-reference-type="milestone" data-placement="left" data-milestone="1">17.0<div>
        <div class="has-popover js-with-popover" data-reference-type="milestone" data-placement="left" data-milestone="2"><span class="child-text">18.0</span><div>
        <div class="has-popover js-iteration-popover" data-reference-type="iteration" data-placement="left" data-iteration="3" data-namespace-path="group/project">Sprint 1<div>
      </div>
    `);
    initWorkItemAttributePopovers();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('calls handleIssuablePopoverMount on mouseover', () => {
    const mockTarget = document.querySelector('.js-with-popover');
    triggerMouseover(mockTarget);

    expect(handleIssuablePopoverMount).toHaveBeenCalledWith(
      expect.objectContaining({
        apolloProvider: expect.any(Object),
        referenceType: 'milestone',
        placement: 'left',
        milestone: '2',
        target: mockTarget,
      }),
    );
  });

  it('mounts popover when hovering over a child element', () => {
    const parentTarget = document.querySelector('.js-with-popover');
    const childTarget = document.querySelector('.child-text');
    triggerMouseover(childTarget);

    expect(handleIssuablePopoverMount).toHaveBeenCalledWith(
      expect.objectContaining({
        target: parentTarget,
        referenceType: 'milestone',
        milestone: '2',
      }),
    );
  });

  it('does not call handleIssuablePopoverMount when target is missing required attributes for popover', () => {
    const mockTarget = document.querySelector('.js-without-popover');
    triggerMouseover(mockTarget);

    expect(handleIssuablePopoverMount).not.toHaveBeenCalled();
  });

  it('calls handleIssuablePopoverMount with iteration data attribute for iteration popover', () => {
    const mockTarget = document.querySelector('.js-iteration-popover');
    triggerMouseover(mockTarget);

    expect(handleIssuablePopoverMount).toHaveBeenCalledWith(
      expect.objectContaining({
        apolloProvider: expect.any(Object),
        referenceType: 'iteration',
        placement: 'left',
        iteration: '3',
        namespacePath: 'group/project',
        target: mockTarget,
      }),
    );
  });

  it.each`
    description                 | attr
    ${'already mounted'}        | ${'popoverMounted'}
    ${'listener already added'} | ${'popoverListenerAdded'}
  `('does not mount popover again if $description', ({ attr }) => {
    const mockTarget = document.querySelector('.js-with-popover');
    mockTarget.dataset[attr] = 'true';
    triggerMouseover(mockTarget);

    expect(handleIssuablePopoverMount).not.toHaveBeenCalled();
  });

  it('calls handleIssuablePopoverMount only once for repeated mouseover events', () => {
    const mockTarget = document.querySelector('.js-with-popover');
    triggerMouseover(mockTarget);
    triggerMouseover(mockTarget);
    triggerMouseover(mockTarget);

    expect(handleIssuablePopoverMount).toHaveBeenCalledTimes(1);
  });
});
