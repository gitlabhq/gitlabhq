const ModalStub = {
  name: 'glmodal-stub',
  template: `
    <div>
      <slot></slot>
      <slot name="modal-footer"></slot>
    </div>
  `,
  methods: {
    hide: jest.fn(),
  },
};

export default ModalStub;
