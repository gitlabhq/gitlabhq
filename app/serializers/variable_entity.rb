class VariableEntity < Grape::Entity
<<<<<<< HEAD
  prepend ::EE::VariableEntity

=======
>>>>>>> upstream/master
  expose :id
  expose :key
  expose :value

  expose :protected?, as: :protected
end
