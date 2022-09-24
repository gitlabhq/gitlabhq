import { Matrix4, MeshLambertMaterial, Mesh } from 'three';

const defaultColor = 0xe24329;
const materials = {
  default: new MeshLambertMaterial({
    color: defaultColor,
  }),
  wireframe: new MeshLambertMaterial({
    color: defaultColor,
    wireframe: true,
  }),
};

export default class MeshObject extends Mesh {
  constructor(geo) {
    super(geo, materials.default);

    this.geometry.computeBoundingSphere();

    this.rotation.set(-Math.PI / 2, 0, 0);

    if (this.geometry.boundingSphere.radius > 4) {
      const scale = 4 / this.geometry.boundingSphere.radius;

      this.geometry.applyMatrix4(new Matrix4().makeScale(scale, scale, scale));
      this.geometry.computeBoundingSphere();

      this.position.x = -this.geometry.boundingSphere.center.x;
      this.position.z = this.geometry.boundingSphere.center.y;
    }
  }

  changeMaterial(materialKey) {
    this.material = materials[materialKey];
  }
}
