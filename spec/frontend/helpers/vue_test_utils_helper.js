/* eslint-disable import/prefer-default-export */

const vNodeContainsText = (vnode, text) =>
  (vnode.text && vnode.text.includes(text)) ||
  (vnode.children && vnode.children.filter(child => vNodeContainsText(child, text)).length);

/**
 * Determines whether a `shallowMount` Wrapper contains text
 * within one of it's slots. This will also work on Wrappers
 * acquired with `find()`, but only if it's parent Wrapper
 * was shallowMounted.
 * NOTE: Prefer checking the rendered output of a component
 * wherever possible using something like `text()` instead.
 * @param {Wrapper} shallowWrapper - Vue test utils wrapper (shallowMounted)
 * @param {String} slotName
 * @param {String} text
 */
export const shallowWrapperContainsSlotText = (shallowWrapper, slotName, text) =>
  Boolean(
    shallowWrapper.vm.$slots[slotName].filter(vnode => vNodeContainsText(vnode, text)).length,
  );
