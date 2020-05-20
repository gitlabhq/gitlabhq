const ModalStub = {
  name: 'glmodal-stub',
  template: `
    <div>
      <slot></slot>
      <slot name="modal-ok"></slot>
    </div>
  `,
};

export default ModalStub;
